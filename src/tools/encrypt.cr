require "../pdfbox"
require "option_parser"

module Tools
  class Encrypt
    @owner_password = ""
    @user_password = ""
    @cert_file_list = [] of String
    @can_assemble_document = true
    @can_extract_content = true
    @can_extract_for_accessibility = true
    @can_fill_in_form = true
    @can_modify = true
    @can_modify_annotations = true
    @can_print = true
    @can_print_faithful = true
    @key_length = 256
    @infile : String? = nil
    @outfile : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infile = @infile
      unless infile
        @err.puts("Missing required option: -i")
        return 1
      end

      outfile = @outfile || infile # Overwrite input if no output specified

      process_document(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error encrypting document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @owner_password = ""
      @user_password = ""
      @cert_file_list.clear
      @can_assemble_document = true
      @can_extract_content = true
      @can_extract_for_accessibility = true
      @can_fill_in_form = true
      @can_modify = true
      @can_modify_annotations = true
      @can_print = true
      @can_print_faithful = true
      @key_length = 256
      @infile = nil
      @outfile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-O PASSWORD", "Set the owner password (ignored if certFile is set)") { |value| @owner_password = value }
        parser.on("-U PASSWORD", "Set the user password (ignored if certFile is set)") { |value| @user_password = value }
        parser.on("--certFile CERTFILE", "Path to X.509 certificate (repeat both if needed)") { |value| @cert_file_list << value }
        parser.on("--canAssemble VALUE", "Set the assemble permission (default: true)") { |value| @can_assemble_document = value.downcase == "true" }
        parser.on("--canExtractContent VALUE", "Set the extraction permission (default: true)") { |value| @can_extract_content = value.downcase == "true" }
        parser.on("--canExtractForAccessibility VALUE", "Set the extraction permission (default: true)") { |value| @can_extract_for_accessibility = value.downcase == "true" }
        parser.on("--canFillInForm VALUE", "Set the form fill in permission (default: true)") { |value| @can_fill_in_form = value.downcase == "true" }
        parser.on("--canModify VALUE", "Set the modify permission (default: true)") { |value| @can_modify = value.downcase == "true" }
        parser.on("--canModifyAnnotations VALUE", "Set the modify annots permission (default: true)") { |value| @can_modify_annotations = value.downcase == "true" }
        parser.on("--canPrint VALUE", "Set the print permission (default: true)") { |value| @can_print = value.downcase == "true" }
        parser.on("--canPrintFaithful VALUE", "Set the print faithful permission (default: true)") { |value| @can_print_faithful = value.downcase == "true" }
        parser.on("--keyLength LENGTH", "Key length in bits (valid values: 40, 128 or 256) (default: 256)") { |value| @key_length = value.to_i }
        parser.on("-i FILE", "--input FILE", "The PDF file to encrypt (required)") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The encrypted PDF file. If omitted the original file is overwritten.") { |value| @outfile = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox encrypt [options]

          Options:
            -O PASSWORD                 Set the owner password (ignored if certFile is set)
            -U PASSWORD                 Set the user password (ignored if certFile is set)
            --certFile CERTFILE         Path to X.509 certificate (repeat both if needed)
            --canAssemble VALUE         Set the assemble permission (default: true)
            --canExtractContent VALUE   Set the extraction permission (default: true)
            --canExtractForAccessibility VALUE Set the extraction permission (default: true)
            --canFillInForm VALUE       Set the form fill in permission (default: true)
            --canModify VALUE           Set the modify permission (default: true)
            --canModifyAnnotations VALUE Set the modify annots permission (default: true)
            --canPrint VALUE            Set the print permission (default: true)
            --canPrintFaithful VALUE    Set the print faithful permission (default: true)
            --keyLength LENGTH          Key length in bits (valid values: 40, 128 or 256) (default: 256)
            -i, --input FILE            The PDF file to encrypt (required)
            -o, --output FILE           The encrypted PDF file. If omitted the original file is overwritten.
            -h, --help                  Show this help

          Examples:
            # Encrypt with owner and user passwords
            pdfbox encrypt -i input.pdf -O ownerpass -U userpass

            # Encrypt with certificate
            pdfbox encrypt -i input.pdf --certFile certificate.pem

            # Encrypt with specific permissions
            pdfbox encrypt -i input.pdf -O ownerpass -U userpass --canPrint false --canModify false
          HELP
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-O", "-U", "-i", "-o", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process_document(infile : String, outfile : String) : Int32
      # Check if input file exists
      unless File.exists?(infile)
        @err.puts("Input file not found: #{infile}")
        return 1
      end

      # Load document
      document = Pdfbox::Loader.load_pdf(infile)

      # Check if already encrypted
      # Note: We don't have is_encrypted? method yet, so we'll skip this check
      # if document.is_encrypted?
      #   @err.puts("Error: Document is already encrypted.")
      #   document.close
      #   return 1
      # end

      # Create access permissions
      ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
      ap.can_assemble_document = @can_assemble_document
      ap.can_extract_content = @can_extract_content
      ap.can_extract_for_accessibility = @can_extract_for_accessibility
      ap.can_fill_in_form = @can_fill_in_form
      ap.can_modify = @can_modify
      ap.can_modify_annotations = @can_modify_annotations
      ap.can_print = @can_print
      ap.can_print_faithful = @can_print_faithful

      if !@cert_file_list.empty?
        # Public key encryption (certificate-based) - not implemented yet
        @err.puts("Error: Public key encryption (certificate-based) is not yet implemented")
        document.close
        return 1
      else
        # Standard password-based encryption
        if @owner_password.empty? && @user_password.empty?
          @err.puts("Error: Either owner password (-O) or user password (-U) must be specified")
          document.close
          return 1
        end

        # Check key length
        unless [40, 128, 256].includes?(@key_length)
          @err.puts("Error: Invalid key length #{@key_length}. Valid values are 40, 128, or 256")
          document.close
          return 1
        end

        # Create protection policy
        policy = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new(@owner_password, @user_password, ap)
        policy.encryption_key_length = @key_length
        document.protect(policy)

        document.save(outfile)
      end

      document.close
      0
    end
  end
end
