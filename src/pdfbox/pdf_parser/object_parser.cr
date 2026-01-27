module Pdfbox::Pdfparser
  # PDF object parser for individual COS objects
  class ObjectParser
    @scanner : PDFScanner
    @parser : Parser?

    def initialize(source : Pdfbox::IO::RandomAccessRead, parser : Parser? = nil)
      @scanner = PDFScanner.new(source)
      @parser = parser
    end

    def initialize(scanner : PDFScanner, parser : Parser? = nil)
      @scanner = scanner
      @parser = parser
    end

    # Parse a COS object from the stream
    def parse_object : Pdfbox::Cos::Base?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_object: rest first 100 chars: #{@scanner.rest[0..100].inspect}"

      char = @scanner.peek
      puts "DEBUG ObjectParser.parse_object: peek char: #{char.inspect}"
      return if char.nil?

      case char
      when '/'
        parse_name
      when '('
        parse_string
      when '<'
        # Could be string (<...>) or dictionary (<<...>>)
        if @scanner.rest.starts_with?("<<")
          parse_dictionary
        else
          parse_string
        end
      when '['
        parse_array
      when '>'
        # Could be end of dictionary or malformed
        nil
      when '0'..'9', '+', '-', '.'
        # Try to parse as indirect reference first (obj gen R)
        ref = parse_reference
        ref ? ref : parse_number
      when 't', 'f'
        parse_boolean
      when 'n'
        parse_null
      else
        # Unknown token, return nil
      end
    end

    # Parse a COS dictionary
    def parse_dictionary : Pdfbox::Cos::Dictionary?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_dictionary: rest first 100 chars: #{@scanner.rest[0..100].inspect}"

      # Dictionary starts with '<<'
      unless @scanner.rest.starts_with?("<<")
        puts "DEBUG ObjectParser.parse_dictionary: does not start with '<<'"
        return
      end

      scanned = @scanner.scanner.scan("<<")
      puts "DEBUG ObjectParser.parse_dictionary: scanned '<<': #{scanned.inspect}, pos: #{@scanner.position}"
      dict = Pdfbox::Cos::Dictionary.new

      loop do
        @scanner.skip_whitespace
        if @scanner.rest.starts_with?(">>")
          puts "DEBUG ObjectParser.parse_dictionary: found '>>', breaking loop"
          break
        end

        # Parse key (must be a name)
        key = parse_name
        unless key
          puts "DEBUG ObjectParser.parse_dictionary: failed to parse key, breaking"
          break
        end
        puts "DEBUG ObjectParser.parse_dictionary: parsed key: #{key.inspect}"

        # Parse value
        value = parse_object
        unless value
          puts "DEBUG ObjectParser.parse_dictionary: failed to parse value for key #{key}, breaking"
          break
        end
        puts "DEBUG ObjectParser.parse_dictionary: parsed value: #{value.class} #{value.inspect}"

        dict[key] = value
      end

      scanned_end = @scanner.scanner.scan(">>")
      puts "DEBUG ObjectParser.parse_dictionary: scanned '>>': #{scanned_end.inspect}, pos after: #{@scanner.position}"
      dict
    end

    # Parse a COS array
    def parse_array : Pdfbox::Cos::Array?
      @scanner.skip_whitespace

      # Array starts with '['
      unless @scanner.scanner.scan('[')
        return
      end

      array = Pdfbox::Cos::Array.new

      loop do
        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        value = parse_object
        break unless value

        array.add(value)

        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        # Arrays can have spaces between elements
      end

      @scanner.scanner.scan(']') rescue nil
      array
    end

    # Parse a COS string
    def parse_string : Pdfbox::Cos::String?
      @scanner.skip_whitespace

      string = @scanner.read_string rescue nil
      return unless string

      Pdfbox::Cos::String.new(string)
    end

    # Parse a COS name
    def parse_name : Pdfbox::Cos::Name?
      @scanner.skip_whitespace

      name = @scanner.read_name rescue nil
      return unless name

      Pdfbox::Cos::Name.new(name)
    end

    # Parse a COS number (integer or float)
    def parse_number : Pdfbox::Cos::Base?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_number: rest first 50 chars: #{@scanner.rest[0..50].inspect}"

      number = @scanner.read_number rescue nil
      puts "DEBUG ObjectParser.parse_number: number=#{number.inspect}"
      return unless number

      case number
      when Int64
        Pdfbox::Cos::Integer.new(number)
      when Float64
        Pdfbox::Cos::Float.new(number)
      end
    end

    # Parse a COS indirect object reference (obj gen R)
    def parse_reference : Pdfbox::Cos::Object?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_reference: rest first 50 chars: #{@scanner.rest[0..50].inspect}"

      # Save scanner position in case we need to rollback
      saved_pos = @scanner.scanner.offset

      # Try to read first integer
      first = @scanner.scanner.scan(/[+-]?\d+/) rescue nil
      puts "DEBUG ObjectParser.parse_reference: first=#{first.inspect}"
      unless first
        @scanner.scanner.offset = saved_pos
        return
      end

      # Must have whitespace after first integer
      @scanner.skip_whitespace

      # Try to read second integer
      second = @scanner.scanner.scan(/[+-]?\d+/) rescue nil
      puts "DEBUG ObjectParser.parse_reference: second=#{second.inspect}"
      unless second
        @scanner.scanner.offset = saved_pos
        return
      end

      # Must have whitespace before 'R'
      @scanner.skip_whitespace

      # Try to read 'R'
      r = @scanner.scanner.scan('R') rescue nil
      puts "DEBUG ObjectParser.parse_reference: r=#{r.inspect}"
      unless r
        # Not a reference, rollback
        @scanner.scanner.offset = saved_pos
        puts "DEBUG ObjectParser.parse_reference: rollback, not a reference"
        return
      end

      # Success - create reference object
      obj_num = first.to_i64
      gen_num = second.to_i64
      puts "DEBUG ObjectParser.parse_reference: success #{obj_num} #{gen_num} R"
      if parser = @parser
        parser.get_object_from_pool(obj_num, gen_num)
      else
        Pdfbox::Cos::Object.new(obj_num, gen_num)
      end
    end

    # Parse a COS boolean
    def parse_boolean : Pdfbox::Cos::Boolean?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("true")
        Pdfbox::Cos::Boolean::TRUE
      elsif @scanner.scanner.scan("false")
        Pdfbox::Cos::Boolean::FALSE
      end
    end

    # Parse a COS null
    def parse_null : Pdfbox::Cos::Null?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("null")
        Pdfbox::Cos::Null.instance
      end
    end

    # Get underlying scanner
    def scanner : PDFScanner
      @scanner
    end
  end
end
