require "xml"

module Pdfbox::Pdmodel::Fdf
  class FDFNamedPageReference
    @cos_object : Pdfbox::Cos::Dictionary
    property name : String?
    property file_specification : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification?

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def write_fdf(io : ::IO) : Nil
      io << "<< "
      if current_name = @name
        io << "/Name " << FDFField.pdf_string(current_name) << " "
      end
      if file_spec = @file_specification
        io << "/F "
        file_spec.cos_object.write_pdf(io)
        io << " "
      end
      io << ">>"
    end
  end

  class FDFTemplate
    @cos_object : Pdfbox::Cos::Dictionary
    property template_reference : FDFNamedPageReference?
    property fields : Array(FDFField)?
    # ameba:disable Naming/QueryBoolMethods
    property rename : Bool = false

    # ameba:enable Naming/QueryBoolMethods

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def should_rename? : Bool
      @rename
    end

    def write_fdf(io : ::IO) : Nil
      io << "<< "
      if template_reference = @template_reference
        io << "/TRef "
        template_reference.write_fdf(io)
        io << " "
      end
      if current_fields = @fields
        io << "/Fields [ "
        current_fields.each do |field|
          field.write_fdf(io)
          io << " "
        end
        io << "] "
      end
      io << "/Rename true " if @rename
      io << ">>"
    end
  end

  class FDFJavaScript
    @cos_object : Pdfbox::Cos::Dictionary

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def before : String?
      javascript_entry("Before")
    end

    def before=(script : String) : String
      @cos_object[Pdfbox::Cos::Name.new("Before")] = Pdfbox::Cos::String.new(script)
      script
    end

    def after : String?
      javascript_entry("After")
    end

    def after=(script : String) : String
      @cos_object[Pdfbox::Cos::Name.new("After")] = Pdfbox::Cos::String.new(script)
      script
    end

    def doc : Hash(String, Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)?
      array = @cos_object[Pdfbox::Cos::Name.new("Doc")]?.as?(Pdfbox::Cos::Array)
      return nil unless array

      map = {} of String => Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript
      i = 0
      while i + 1 < array.size
        key = array[i]?.as?(Pdfbox::Cos::String).try(&.value)
        action_dict = array[i + 1]?.as?(Pdfbox::Cos::Dictionary)
        if key && action_dict
          map[key] = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new(action_dict)
        end
        i += 2
      end
      map
    end

    def doc=(actions : Hash(String, Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)) : Hash(String, Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
      array = Pdfbox::Cos::Array.new
      actions.each do |name, action|
        array.add(Pdfbox::Cos::String.new(name))
        array.add(action.cos_object)
      end
      @cos_object[Pdfbox::Cos::Name.new("Doc")] = array
      actions
    end

    private def javascript_entry(name : String) : String?
      value = @cos_object[Pdfbox::Cos::Name.new(name)]?
      case value
      when Pdfbox::Cos::String
        value.value
      when Pdfbox::Cos::Stream
        value.create_input_stream.gets_to_end
      else
        nil
      end
    end
  end

  class FDFPageInfo
    @cos_object : Pdfbox::Cos::Dictionary

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end
  end

  class FDFPage
    @cos_object : Pdfbox::Cos::Dictionary
    property page_info : FDFPageInfo?
    property templates : Array(FDFTemplate)?

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def page_info : FDFPageInfo?
      @page_info
    end

    def page_info=(page_info : FDFPageInfo?) : FDFPageInfo?
      @page_info = page_info
    end

    def write_fdf(io : ::IO) : Nil
      io << "<< "
      if info = @page_info
        io << "/Info "
        info.cos_object.write_pdf(io)
        io << " "
      end
      if current_templates = @templates
        io << "/Templates [ "
        current_templates.each do |template|
          template.write_fdf(io)
          io << " "
        end
        io << "] "
      end
      io << ">>"
    end
  end

  class FDFField
    property partial_field_name : String?
    property cos_value : Pdfbox::Cos::Base?
    property rich_text : String?
    property kids : Array(FDFField)?
    property action : Pdfbox::Pdmodel::Interactive::Action::PDAction?
    property additional_actions : Pdfbox::Pdmodel::Interactive::Action::PDAdditionalActions?
    property appearance_dictionary : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary?
    property appearance_stream_reference : FDFNamedPageReference?
    property icon_fit : FDFIconFit?
    property options : Array(String | FDFOptionElement)?
    property field_flags : Int32?
    property set_field_flags : Int32?
    property clear_field_flags : Int32?
    property widget_field_flags : Int32?
    property set_widget_field_flags : Int32?
    property clear_widget_field_flags : Int32?

    def initialize
    end

    def initialize(@partial_field_name : String?, @cos_value : Pdfbox::Cos::Base? = nil, @kids : Array(FDFField)? = nil, @rich_text : String? = nil)
    end

    def value : String | Array(String) | Nil
      current = @cos_value
      case current
      when Pdfbox::Cos::Name
        current.value
      when Pdfbox::Cos::String
        current.value
      when Pdfbox::Cos::Array
        current.to_cos_string_string_list.compact
      when Pdfbox::Cos::Stream
        current.create_input_stream.gets_to_end
      else
        nil
      end
    end

    def value=(value : String) : Nil
      @cos_value = Pdfbox::Cos::String.new(value)
    end

    def value=(values : Array(String)) : Nil
      array = Pdfbox::Cos::Array.new
      values.each { |value| array.add(Pdfbox::Cos::String.new(value)) }
      @cos_value = array
    end

    def write_xfdf(io : ::IO, indent : String = "  ") : Nil
      io << indent << %(<field name=") << self.class.escape_xml(@partial_field_name.to_s) << %(">\n)

      case current = value
      when String
        io << indent << "  <value>" << self.class.escape_xml(current) << "</value>\n"
      when Array(String)
        current.each do |item|
          io << indent << "  <value>" << self.class.escape_xml(item) << "</value>\n"
        end
      end

      if rt = @rich_text
        io << indent << "  <value-richtext>" << self.class.escape_xml(rt) << "</value-richtext>\n"
      end

      @kids.try(&.each(&.write_xfdf(io, indent + "  ")))
      io << indent << "</field>\n"
    end

    def write_fdf(io : ::IO) : Nil
      io << "<< "
      if name = @partial_field_name
        io << "/T " << self.class.pdf_string(name) << " "
      end

      if cos_value = @cos_value
        io << "/V "
        self.class.write_cos_value(io, cos_value)
        io << " "
      end

      if kids = @kids
        io << "/Kids [ "
        kids.each do |kid|
          kid.write_fdf(io)
          io << " "
        end
        io << "] "
      end

      if rich_text = @rich_text
        io << "/RV " << self.class.pdf_string(rich_text) << " "
      end
      if action = @action
        io << "/A "
        action.cos_object.write_pdf(io)
        io << " "
      end
      if additional_actions = @additional_actions
        io << "/AA "
        additional_actions.cos_object.write_pdf(io)
        io << " "
      end
      if appearance_dictionary = @appearance_dictionary
        io << "/AP "
        appearance_dictionary.cos_object.write_pdf(io)
        io << " "
      end
      if appearance_stream_reference = @appearance_stream_reference
        io << "/APRef "
        appearance_stream_reference.write_fdf(io)
        io << " "
      end
      if icon_fit = @icon_fit
        io << "/IF "
        icon_fit.cos_object.write_pdf(io)
        io << " "
      end
      write_options_fdf(io)
      write_flag_entries_fdf(io)
      io << ">>"
    end

    private def write_options_fdf(io : ::IO) : Nil
      return unless options = @options

      io << "/Opt [ "
      options.each do |option|
        case option
        when String
          io << self.class.pdf_string(option) << " "
        when FDFOptionElement
          option.cos_array.write_pdf(io)
          io << " "
        end
      end
      io << "] "
    end

    private def write_flag_entries_fdf(io : ::IO) : Nil
      write_optional_int_fdf(io, "Ff", @field_flags)
      write_optional_int_fdf(io, "SetFf", @set_field_flags)
      write_optional_int_fdf(io, "ClrFf", @clear_field_flags)
      write_optional_int_fdf(io, "F", @widget_field_flags)
      write_optional_int_fdf(io, "SetF", @set_widget_field_flags)
      write_optional_int_fdf(io, "ClrF", @clear_widget_field_flags)
    end

    private def write_optional_int_fdf(io : ::IO, name : String, value : Int32?) : Nil
      return unless current_value = value

      io << "/" << name << " " << current_value << " "
    end

    def self.from_xfdf(node : XML::Node) : self
      field = new
      field.partial_field_name = node["name"]?

      kids = [] of FDFField
      values = [] of String
      node.children.each do |child|
        next unless child.element?

        case child.name
        when "value"
          values << child.content
        when "value-richtext"
          field.rich_text = child.content
        when "field"
          kids << from_xfdf(child)
        end
      end

      field.value = values.size == 1 ? values[0] : values if values.size > 1 || values.size == 1
      field.kids = kids unless kids.empty?
      field
    end

    def self.escape_xml(text : String) : String
      text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub("\"", "&quot;")
    end

    def self.pdf_string(text : String) : String
      "(" + text.gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)") + ")"
    end

    def self.write_cos_value(io : ::IO, value : Pdfbox::Cos::Base) : Nil
      case value
      when Pdfbox::Cos::Name
        io << "/" << value.value
      when Pdfbox::Cos::String
        io << pdf_string(value.value)
      when Pdfbox::Cos::Array
        io << "[ "
        value.items.each do |item|
          write_cos_value(io, item)
          io << " "
        end
        io << "]"
      when Pdfbox::Cos::Stream
        io << pdf_string(value.create_input_stream.gets_to_end)
      else
        value.write_pdf(io)
      end
    end
  end

  class FDFOptionElement
    @cos_array : Pdfbox::Cos::Array

    def initialize
      @cos_array = Pdfbox::Cos::Array.new
      @cos_array.add(Pdfbox::Cos::String.new(""))
      @cos_array.add(Pdfbox::Cos::String.new(""))
    end

    def initialize(@cos_array : Pdfbox::Cos::Array)
    end

    def cos_object : Pdfbox::Cos::Base
      @cos_array
    end

    def cos_array : Pdfbox::Cos::Array
      @cos_array
    end

    def option : String?
      @cos_array[0]?.as?(Pdfbox::Cos::String).try(&.value)
    end

    def option=(value : String) : String
      @cos_array[0] = Pdfbox::Cos::String.new(value)
      value
    end

    def default_appearance_string : String?
      @cos_array[1]?.as?(Pdfbox::Cos::String).try(&.value)
    end

    def default_appearance_string=(value : String) : String
      @cos_array[1] = Pdfbox::Cos::String.new(value)
      value
    end
  end

  class FDFIconFit
    SCALE_OPTION_ALWAYS                    = "A"
    SCALE_OPTION_ONLY_WHEN_ICON_IS_BIGGER  = "B"
    SCALE_OPTION_ONLY_WHEN_ICON_IS_SMALLER = "S"
    SCALE_OPTION_NEVER                     = "N"
    SCALE_TYPE_ANAMORPHIC                  = "A"
    SCALE_TYPE_PROPORTIONAL                = "P"

    @cos_object : Pdfbox::Cos::Dictionary

    def initialize(@cos_object : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def scale_option : String
      @cos_object[Pdfbox::Cos::Name.new("SW")]?.as?(Pdfbox::Cos::Name).try(&.value) || SCALE_OPTION_ALWAYS
    end

    def scale_option=(option : String) : String
      @cos_object[Pdfbox::Cos::Name.new("SW")] = Pdfbox::Cos::Name.new(option)
      option
    end

    def scale_type : String
      @cos_object[Pdfbox::Cos::Name.new("S")]?.as?(Pdfbox::Cos::Name).try(&.value) || SCALE_TYPE_PROPORTIONAL
    end

    def scale_type=(scale : String) : String
      @cos_object[Pdfbox::Cos::Name.new("S")] = Pdfbox::Cos::Name.new(scale)
      scale
    end

    def fractional_space_to_allocate : Pdfbox::Pdmodel::Common::PDRange
      array = @cos_object[Pdfbox::Cos::Name.new("A")]?.as?(Pdfbox::Cos::Array)
      return Pdfbox::Pdmodel::Common::PDRange.new(array) if array

      range = Pdfbox::Pdmodel::Common::PDRange.new
      range.min = 0.5
      range.max = 0.5
      self.fractional_space_to_allocate = range
      range
    end

    def fractional_space_to_allocate=(space : Pdfbox::Pdmodel::Common::PDRange) : Pdfbox::Pdmodel::Common::PDRange
      @cos_object[Pdfbox::Cos::Name.new("A")] = space.cos_object
      space
    end

    def should_scale_to_fit_annotation? : Bool
      @cos_object[Pdfbox::Cos::Name.new("FB")]?.as?(Pdfbox::Cos::Boolean).try(&.value) || false
    end

    def scale_to_fit_annotation=(value : Bool) : Bool
      @cos_object[Pdfbox::Cos::Name.new("FB")] = Pdfbox::Cos::Boolean.get(value)
      value
    end
  end

  class FDFDictionary
    @cos_object = Pdfbox::Cos::Dictionary.new

    property file : String?
    property id : Array(String)?
    property fields : Array(FDFField)?
    property status : String?
    property target : String?
    property encoding : String? = "PDFDocEncoding"
    property pages : Array(FDFPage)?
    property javascript : FDFJavaScript?

    def initialize
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def write_xfdf(io : ::IO) : Nil
      if current_file = @file
        io << %(<f href=") << FDFField.escape_xml(current_file) << %(" />\n)
      end
      if ids = @id
        if ids.size >= 2
          io << %(<ids original=") << FDFField.escape_xml(ids[0]) << %(" modified=") << FDFField.escape_xml(ids[1]) << %(" />\n)
        end
      end
      if exported_fields = @fields
        io << "<fields>\n"
        exported_fields.each(&.write_xfdf(io))
        io << "</fields>\n"
      end
    end
  end

  class FDFCatalog
    @cos_object = Pdfbox::Cos::Dictionary.new

    property fdf : FDFDictionary
    property version : String?

    def initialize
      @fdf = FDFDictionary.new
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @cos_object
    end

    def write_xfdf(io : ::IO) : Nil
      @fdf.write_xfdf(io)
    end
  end

  class FDFDocument
    property catalog : FDFCatalog

    def initialize
      @catalog = FDFCatalog.new
    end

    def self.load_xfdf(path : String) : self
      from_xfdf(File.read(path))
    end

    def self.load_fdf(path : String) : self
      content = File.read(path)
      if content.lstrip.starts_with?("<")
        from_xfdf(content)
      else
        from_fdf(content)
      end
    end

    def self.from_xfdf(content : String) : self
      doc = XML.parse(content)
      root = doc.children.find(&.element?) || raise ::IO::Error.new("XFDF root element missing")
      unless root.name == "xfdf"
        raise ::IO::Error.new("Error while importing xfdf document, root should be 'xfdf' and not '#{root.name}'")
      end

      result = new
      populate_from_xfdf_root(result.catalog.fdf, root)
      result
    end

    def self.from_fdf(content : String) : self
      parser = FDFSyntaxParser.new(content)
      parser.parse
    end

    def save(path : String) : Nil
      File.write(path, to_fdf)
    end

    def save(io : ::IO) : Nil
      io << to_fdf
    end

    def save_xfdf(path : String) : Nil
      File.write(path, to_xfdf)
    end

    def save_xfdf(io : ::IO) : Nil
      io << to_xfdf
    end

    def get_document : Nil # ameba:disable Naming/AccessorMethodName
      nil
    end

    def set_catalog(catalog : FDFCatalog) : FDFCatalog # ameba:disable Naming/AccessorMethodName
      @catalog = catalog
    end

    def close : Nil
    end

    def to_xfdf : String
      String.build do |io|
        io << %(<?xml version="1.0" encoding="UTF-8"?>\n)
        io << %(<xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve">\n)
        @catalog.write_xfdf(io)
        io << "</xfdf>\n"
      end
    end

    def to_fdf : String
      String.build do |io|
        io << "%FDF-1.2\n"
        io << "1 0 obj\n"
        io << "<< "
        if version = @catalog.version
          io << "/Version /" << version << " "
        end
        io << "/FDF << "
        if file = @catalog.fdf.file
          io << "/F " << FDFField.pdf_string(file) << " "
        end
        if ids = @catalog.fdf.id
          if ids.size >= 2
            io << "/ID [ " << FDFField.pdf_string(ids[0]) << " " << FDFField.pdf_string(ids[1]) << " ] "
          end
        end
        if fields = @catalog.fdf.fields
          io << "/Fields [ "
          fields.each do |field|
            field.write_fdf(io)
            io << " "
          end
          io << "] "
        end
        if pages = @catalog.fdf.pages
          io << "/Pages [ "
          pages.each do |page|
            page.write_fdf(io)
            io << " "
          end
          io << "] "
        end
        if javascript = @catalog.fdf.javascript
          io << "/JavaScript "
          javascript.cos_object.write_pdf(io)
          io << " "
        end
        if status = @catalog.fdf.status
          io << "/Status " << FDFField.pdf_string(status) << " "
        end
        if target = @catalog.fdf.target
          io << "/Target " << FDFField.pdf_string(target) << " "
        end
        if encoding = @catalog.fdf.encoding
          io << "/Encoding /" << encoding << " "
        end
        io << ">> >>\n"
        io << "endobj\n"
        io << "trailer\n"
        io << "<< /Root 1 0 R >>\n"
        io << "%%EOF\n"
      end
    end

    private class FDFSyntaxParser
      record NameToken, value : String

      @text : String
      @index = 0

      def initialize(@text : String)
      end

      def parse : FDFDocument
        fields = [] of FDFField
        file = nil.as(String?)
        ids = nil.as(Array(String)?)
        pages = [] of FDFPage
        status = nil.as(String?)
        target = nil.as(String?)
        encoding = nil.as(String?)
        javascript = nil.as(FDFJavaScript?)

        if dict = parse_first_dictionary
          if fdf = dict["FDF"]?.as?(Hash(String, ASTNode))
            file = fdf["F"]?.as?(String)
            ids = parse_ids(fdf["ID"]?)
            status = fdf["Status"]?.as?(String)
            target = fdf["Target"]?.as?(String)
            encoding = name_token_value(fdf["Encoding"]?)
            if field_nodes = fdf["Fields"]?.as?(Array(ASTNode))
              fields = field_nodes.compact_map { |node| field_from_ast(node) }
            end
            if page_nodes = fdf["Pages"]?.as?(Array(ASTNode))
              pages = page_nodes.compact_map { |node| page_from_ast(node) }
            end
            if js_dict = fdf["JavaScript"]?.as?(Hash(String, ASTNode))
              javascript = FDFJavaScript.new(dictionary_from_ast(js_dict))
            end
          end
        end

        doc = FDFDocument.new
        doc.catalog.fdf.file = file
        doc.catalog.fdf.id = ids
        doc.catalog.fdf.status = status
        doc.catalog.fdf.target = target
        doc.catalog.fdf.encoding = encoding if encoding
        doc.catalog.fdf.fields = fields unless fields.empty?
        doc.catalog.fdf.pages = pages unless pages.empty?
        doc.catalog.fdf.javascript = javascript
        doc
      end

      alias ASTNode = String | Hash(String, ASTNode) | Array(ASTNode) | NameToken | Nil

      private def parse_first_dictionary : Hash(String, ASTNode)?
        start = @text.index("<<") || return nil
        @index = start
        parse_dict
      end

      private def parse_dict : Hash(String, ASTNode)
        expect("<<")
        dict = {} of String => ASTNode
        loop do
          skip_ws
          break if consume(">>")
          key = parse_name
          value = parse_value
          dict[key] = value
        end
        dict
      end

      private def parse_array : Array(ASTNode)
        expect("[")
        values = [] of ASTNode
        loop do
          skip_ws
          break if consume("]")
          values << parse_value
        end
        values
      end

      private def parse_value : ASTNode
        skip_ws
        if peek("<<")
          parse_dict
        elsif peek("[")
          parse_array
        elsif peek("(")
          parse_string
        elsif peek("/")
          NameToken.new(parse_name)
        else
          parse_token
        end
      end

      private def parse_name : String
        expect("/")
        start = @index
        while @index < @text.bytesize
          char = @text.byte_at(@index).chr
          break if char.whitespace? || {'/', '[', ']', '<', '>', '(', ')'}.includes?(char)
          @index += 1
        end
        @text.byte_slice(start, @index - start)
      end

      private def parse_string : String
        expect("(")
        String.build do |io|
          depth = 1
          escaped = false
          while @index < @text.bytesize
            char = @text.byte_at(@index).chr
            @index += 1
            if escaped
              io << char
              escaped = false
              next
            end
            case char
            when '\\'
              escaped = true
            when '('
              depth += 1
              io << char
            when ')'
              depth -= 1
              break if depth == 0
              io << char
            else
              io << char
            end
          end
        end
      end

      private def parse_token : String?
        start = @index
        while @index < @text.bytesize
          char = @text.byte_at(@index).chr
          break if char.whitespace? || {'[', ']', '<', '>', '(', ')', '/'}.includes?(char)
          @index += 1
        end
        token = @text.byte_slice(start, @index - start)
        token.empty? ? nil : token
      end

      private def parse_ids(node : ASTNode?) : Array(String)?
        values = node.as?(Array(ASTNode)) || return nil
        ids = [] of String
        values.each do |value|
          if string = value.as?(String)
            ids << string
          end
        end
        ids.empty? ? nil : ids
      end

      private def name_token_value(node : ASTNode?) : String?
        node.as?(NameToken).try(&.value)
      end

      private def field_from_ast(node : ASTNode) : FDFField?
        dict = node.as?(Hash(String, ASTNode)) || return nil
        field = FDFField.new
        populate_field_scalar_entries(field, dict)
        populate_field_value_and_kids(field, dict)
        populate_field_extended_entries(field, dict)
        field
      end

      private def populate_field_scalar_entries(field : FDFField, dict : Hash(String, ASTNode)) : Nil
        field.partial_field_name = dict["T"]?.as?(String)
        field.field_flags = dict["Ff"]?.as?(String).try(&.to_i32)
        field.set_field_flags = dict["SetFf"]?.as?(String).try(&.to_i32)
        field.clear_field_flags = dict["ClrFf"]?.as?(String).try(&.to_i32)
        field.widget_field_flags = dict["F"]?.as?(String).try(&.to_i32)
        field.set_widget_field_flags = dict["SetF"]?.as?(String).try(&.to_i32)
        field.clear_widget_field_flags = dict["ClrF"]?.as?(String).try(&.to_i32)
        field.rich_text = dict["RV"]?.as?(String)
      end

      private def populate_field_value_and_kids(field : FDFField, dict : Hash(String, ASTNode)) : Nil
        if value = dict["V"]?
          field.cos_value = cos_value_from_ast(value)
        end

        if kids_ast = dict["Kids"]?.as?(Array(ASTNode))
          kids = [] of FDFField
          kids_ast.each do |kid|
            if parsed = field_from_ast(kid)
              kids << parsed
            end
          end
          field.kids = kids unless kids.empty?
        end
      end

      private def populate_field_extended_entries(field : FDFField, dict : Hash(String, ASTNode)) : Nil
        if action = dict["A"]?.as?(Hash(String, ASTNode))
          field.action = action_from_ast(action)
        end
        if additional_actions = dict["AA"]?.as?(Hash(String, ASTNode))
          field.additional_actions = additional_actions_from_ast(additional_actions)
        end
        if appearance_dictionary = dict["AP"]?.as?(Hash(String, ASTNode))
          field.appearance_dictionary = appearance_dictionary_from_ast(appearance_dictionary)
        end
        if appearance_reference = dict["APRef"]?.as?(Hash(String, ASTNode))
          field.appearance_stream_reference = named_page_reference_from_ast(appearance_reference)
        end
        if icon_fit = dict["IF"]?.as?(Hash(String, ASTNode))
          field.icon_fit = icon_fit_from_ast(icon_fit)
        end
        if options = options_from_ast(dict["Opt"]?)
          field.options = options
        end
      end

      private def options_from_ast(node : ASTNode?) : Array(String | FDFOptionElement)?
        option_nodes = node.as?(Array(ASTNode)) || return nil
        options = [] of String | FDFOptionElement
        option_nodes.each do |option_node|
          case option_node
          when String
            options << option_node
          when Array(ASTNode)
            option_array = Pdfbox::Cos::Array.new
            option_node.each do |item|
              option_array.add(cos_value_from_ast(item) || Pdfbox::Cos::String.new(""))
            end
            options << FDFOptionElement.new(option_array)
          end
        end
        options.empty? ? nil : options
      end

      private def action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDAction?
        subtype = name_token_value(node["S"]?)
        case subtype
        when Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript::SUB_TYPE
          javascript_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionURI::SUB_TYPE
          uri_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionNamed::SUB_TYPE
          named_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo::SUB_TYPE
          embedded_goto_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionHide::SUB_TYPE
          hide_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm::SUB_TYPE
          submit_form_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch::SUB_TYPE
          launch_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo::SUB_TYPE
          goto_action_from_ast(node)
        when Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo::SUB_TYPE
          remote_goto_action_from_ast(node)
        else
          Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(dictionary_from_ast(node))
        end
      end

      private def javascript_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new(dictionary_from_ast(node))
        if script = node["JS"]?.as?(String)
          action.action = script
        end
        action
      end

      private def uri_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionURI
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
        action.uri = node["URI"]?.as?(String).to_s if node["URI"]?.as?(String)
        if is_map = node["IsMap"]?.as?(String)
          action.track_mouse_position = is_map == "true"
        end
        action
      end

      private def named_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionNamed
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionNamed.new
        if name = name_token_value(node["N"]?)
          action.n = name
        elsif name = node["N"]?.as?(String)
          action.n = name
        end
        action
      end

      private def hide_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionHide
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionHide.new
        if target = cos_value_from_ast(node["T"]?)
          action.t = target
        end
        if hidden = node["H"]?.as?(String)
          action.h = hidden == "true"
        end
        action
      end

      private def submit_form_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm.new
        if file_node = node["F"]?
          if file_spec_base = cos_value_from_ast(file_node)
            if file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(file_spec_base)
              action.file = file_spec
            end
          end
        end
        if field_nodes = node["Fields"]?.as?(Array(ASTNode))
          action.fields = generic_array_from_ast(field_nodes)
        end
        if flags = ast_int(node["Flags"]?)
          action.flags = flags
        end
        action
      end

      private def embedded_goto_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo.new
        populate_embedded_goto_file(action, node["F"]?)
        if destination = embedded_destination_from_ast(node["D"]?)
          action.destination = destination
        end
        if target = node["T"]?.as?(Hash(String, ASTNode))
          action.target_directory = target_directory_from_ast(target)
        end
        populate_embedded_goto_open_mode(action, node)
        action
      end

      private def populate_embedded_goto_file(action : Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo, node : ASTNode?) : Nil
        return unless file_node = node
        return unless file_spec_base = cos_value_from_ast(file_node)
        return unless file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(file_spec_base)

        action.file = file_spec
      end

      private def populate_embedded_goto_open_mode(action : Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo, node : Hash(String, ASTNode)) : Nil
        return unless new_window = node["NewWindow"]?.as?(String)

        action.open_in_new_window =
          case new_window
          when "true"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow
          when "false"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow
          else
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::UserPreference
          end
      end

      private def launch_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch.new
        populate_launch_file(action, node["F"]?)
        populate_launch_scalars(action, node)
        if win = node["Win"]?.as?(Hash(String, ASTNode))
          action.win_launch_params = windows_launch_params_from_ast(win)
        end
        action
      end

      private def populate_launch_file(action : Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch, node : ASTNode?) : Nil
        return unless file_node = node
        return unless file_spec_base = cos_value_from_ast(file_node)

        if file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(file_spec_base)
          action.file = file_spec
        elsif file_name = file_node.as?(String)
          action.f = file_name
        end
      end

      private def populate_launch_scalars(action : Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch, node : Hash(String, ASTNode)) : Nil
        action.d = node["D"]?.as?(String).to_s if node["D"]?.as?(String)
        action.o = node["O"]?.as?(String).to_s if node["O"]?.as?(String)
        action.p = node["P"]?.as?(String).to_s if node["P"]?.as?(String)
        return unless new_window = node["NewWindow"]?.as?(String)

        action.open_in_new_window =
          case new_window
          when "true"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow
          when "false"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow
          else
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::UserPreference
          end
      end

      private def additional_actions_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDAdditionalActions
        actions = Pdfbox::Pdmodel::Interactive::Action::PDAdditionalActions.new
        if f_action = node["F"]?.as?(Hash(String, ASTNode))
          if action = action_from_ast(f_action)
            actions.f = action
          end
        end
        actions
      end

      private def appearance_dictionary_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary
        dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
        if normal = appearance_entry_from_ast(node["N"]?)
          dictionary.normal_appearance = normal
        end
        if rollover = appearance_entry_from_ast(node["R"]?)
          dictionary.rollover_appearance = rollover
        end
        if down = appearance_entry_from_ast(node["D"]?)
          dictionary.down_appearance = down
        end
        dictionary
      end

      private def appearance_entry_from_ast(node : ASTNode?) : Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry?
        case node
        when Hash(String, ASTNode)
          Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(dictionary_from_ast(node))
        else
          nil
        end
      end

      private def windows_launch_params_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDWindowsLaunchParams
        params = Pdfbox::Pdmodel::Interactive::Action::PDWindowsLaunchParams.new
        if filename = node["F"]?.as?(String)
          params.filename = filename
        end
        if directory = node["D"]?.as?(String)
          params.directory = directory
        end
        if operation = node["O"]?.as?(String)
          params.operation = operation
        end
        if execute_param = node["P"]?.as?(String)
          params.execute_param = execute_param
        end
        params
      end

      private def goto_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo.new
        if destination = destination_from_ast(node["D"]?)
          action.destination = destination
        end
        action
      end

      private def remote_goto_action_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo
        action = Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo.new
        populate_remote_goto_file(action, node["F"]?)
        if destination = remote_destination_base_from_ast(node["D"]?)
          action.d = destination
        end
        populate_remote_goto_open_mode(action, node)
        action
      end

      private def populate_remote_goto_file(action : Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo, node : ASTNode?) : Nil
        return unless file_node = node
        return unless file_spec_base = cos_value_from_ast(file_node)

        if file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(file_spec_base)
          action.file = file_spec
        end
      end

      private def populate_remote_goto_open_mode(action : Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo, node : Hash(String, ASTNode)) : Nil
        return unless new_window = node["NewWindow"]?.as?(String)

        action.open_in_new_window =
          case new_window
          when "true"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow
          when "false"
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow
          else
            Pdfbox::Pdmodel::Interactive::Action::OpenMode::UserPreference
          end
      end

      private def destination_from_ast(node : ASTNode?) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination?
        case node
        when String
          Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(node)
        when NameToken
          Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(Pdfbox::Cos::Name.new(node.value))
        when Array(ASTNode)
          destination_from_array_ast(node)
        else
          nil
        end
      end

      private def remote_destination_base_from_ast(node : ASTNode?) : Pdfbox::Cos::Base?
        case node
        when String
          Pdfbox::Cos::String.new(node)
        when NameToken
          Pdfbox::Cos::Name.new(node.value)
        when Array(ASTNode)
          remote_destination_array_from_ast(node)
        else
          cos_value_from_ast(node)
        end
      end

      private def embedded_destination_from_ast(node : ASTNode?) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination?
        case node
        when String
          Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(node)
        when NameToken
          Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(Pdfbox::Cos::Name.new(node.value))
        when Array(ASTNode)
          Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(remote_destination_array_from_ast(node))
        else
          nil
        end
      end

      private def destination_from_array_ast(node : Array(ASTNode)) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination?
        array = destination_array_from_ast(node)
        Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(array)
      end

      private def destination_array_from_ast(node : Array(ASTNode)) : Pdfbox::Cos::Array
        array = Pdfbox::Cos::Array.new
        node.each_with_index do |item, index|
          cos_value =
            case item
            when String
              if index > 1
                if integer_value = item.to_i64?
                  Pdfbox::Cos::Integer.new(integer_value)
                elsif float_value = item.to_f64?
                  Pdfbox::Cos::Float.new(float_value)
                else
                  Pdfbox::Cos::String.new(item)
                end
              else
                Pdfbox::Cos::String.new(item)
              end
            when NameToken
              Pdfbox::Cos::Name.new(item.value)
            when Hash(String, ASTNode)
              dictionary_from_ast(item)
            else
              cos_value_from_ast(item)
            end
          array.add(cos_value || Pdfbox::Cos::Null.instance)
        end
        array
      end

      private def target_directory_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Pdmodel::Interactive::Action::PDTargetDirectory
        target = Pdfbox::Pdmodel::Interactive::Action::PDTargetDirectory.new
        if relationship = name_token_value(node["R"]?)
          target.relationship = Pdfbox::Cos::Name.new(relationship)
        end
        target.filename = node["N"]?.as?(String)
        if nested_target = node["T"]?.as?(Hash(String, ASTNode))
          target.target_directory = target_directory_from_ast(nested_target)
        end
        if page_name = node["P"]?.as?(String)
          if page_number = page_name.to_i?
            target.page_number = page_number
          else
            target.named_destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(page_name)
          end
        end
        if annotation_name = node["A"]?.as?(String)
          if annotation_index = annotation_name.to_i?
            target.annotation_index = annotation_index
          else
            target.annotation_name = annotation_name
          end
        end
        target
      end

      private def generic_array_from_ast(node : Array(ASTNode)) : Pdfbox::Cos::Array
        array = Pdfbox::Cos::Array.new
        node.each do |item|
          array.add(cos_value_from_ast(item) || Pdfbox::Cos::Null.instance)
        end
        array
      end

      private def ast_int(node : ASTNode?) : Int32?
        case node
        when String
          node.to_i?
        else
          nil
        end
      end

      private def remote_destination_array_from_ast(node : Array(ASTNode)) : Pdfbox::Cos::Array
        array = Pdfbox::Cos::Array.new
        node.each_with_index do |item, index|
          cos_value =
            case item
            when String
              if index != 1
                if integer_value = item.to_i64?
                  Pdfbox::Cos::Integer.new(integer_value)
                elsif float_value = item.to_f64?
                  Pdfbox::Cos::Float.new(float_value)
                else
                  Pdfbox::Cos::String.new(item)
                end
              else
                Pdfbox::Cos::String.new(item)
              end
            when NameToken
              Pdfbox::Cos::Name.new(item.value)
            when Hash(String, ASTNode)
              dictionary_from_ast(item)
            else
              cos_value_from_ast(item)
            end
          array.add(cos_value || Pdfbox::Cos::Null.instance)
        end
        array
      end

      private def page_from_ast(node : ASTNode) : FDFPage?
        dict = node.as?(Hash(String, ASTNode)) || return nil
        page = FDFPage.new
        if info_dict = dict["Info"]?.as?(Hash(String, ASTNode))
          page.page_info = FDFPageInfo.new(dictionary_from_ast(info_dict))
        end
        if template_nodes = dict["Templates"]?.as?(Array(ASTNode))
          templates = template_nodes.compact_map { |template_node| template_from_ast(template_node) }
          page.templates = templates unless templates.empty?
        end
        page
      end

      private def template_from_ast(node : ASTNode) : FDFTemplate?
        dict = node.as?(Hash(String, ASTNode)) || return nil
        template = FDFTemplate.new
        if tref_dict = dict["TRef"]?.as?(Hash(String, ASTNode))
          template.template_reference = named_page_reference_from_ast(tref_dict)
        end
        if field_nodes = dict["Fields"]?.as?(Array(ASTNode))
          fields = field_nodes.compact_map { |field_node| field_from_ast(field_node) }
          template.fields = fields unless fields.empty?
        end
        template.rename = dict["Rename"]?.as?(String) == "true"
        template
      end

      private def named_page_reference_from_ast(node : Hash(String, ASTNode)) : FDFNamedPageReference
        reference = FDFNamedPageReference.new
        reference.name = node["Name"]?.as?(String)
        if file_node = node["F"]?
          if file_spec_base = cos_value_from_ast(file_node)
            reference.file_specification = Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(file_spec_base)
          end
        end
        reference
      end

      private def icon_fit_from_ast(node : Hash(String, ASTNode)) : FDFIconFit
        icon_fit = FDFIconFit.new
        if scale_option = name_token_value(node["SW"]?)
          icon_fit.scale_option = scale_option
        end
        if scale_type = name_token_value(node["S"]?)
          icon_fit.scale_type = scale_type
        end
        if allocation = node["A"]?.as?(Array(ASTNode))
          range_array = Pdfbox::Cos::Array.new
          allocation.each do |item|
            case item
            when String
              if integer_value = item.to_i64?
                range_array.add(Pdfbox::Cos::Integer.new(integer_value))
              elsif float_value = item.to_f64?
                range_array.add(Pdfbox::Cos::Float.new(float_value))
              end
            end
          end
          if range_array.size >= 2
            icon_fit.fractional_space_to_allocate = Pdfbox::Pdmodel::Common::PDRange.new(range_array)
          end
        end
        if scale_to_fit = node["FB"]?.as?(String)
          icon_fit.scale_to_fit_annotation = scale_to_fit == "true"
        end
        icon_fit
      end

      private def cos_value_from_ast(node : ASTNode) : Pdfbox::Cos::Base?
        case node
        when String
          Pdfbox::Cos::String.new(node)
        when NameToken
          Pdfbox::Cos::Name.new(node.value)
        when Array(ASTNode)
          array = Pdfbox::Cos::Array.new
          node.each do |item|
            if value = cos_value_from_ast(item)
              array.add(value)
            end
          end
          array
        when Hash(String, ASTNode)
          dictionary_from_ast(node)
        else
          nil
        end
      end

      private def dictionary_from_ast(node : Hash(String, ASTNode)) : Pdfbox::Cos::Dictionary
        dictionary = Pdfbox::Cos::Dictionary.new
        node.each do |key, value|
          if cos_value = cos_value_from_ast(value)
            dictionary[Pdfbox::Cos::Name.new(key)] = cos_value
          end
        end
        dictionary
      end

      private def skip_ws : Nil
        while @index < @text.bytesize && @text.byte_at(@index).chr.whitespace?
          @index += 1
        end
      end

      private def peek(token : String) : Bool
        @text.byte_slice(@index, token.bytesize) == token
      end

      private def consume(token : String) : Bool
        return false unless peek(token)
        @index += token.bytesize
        true
      end

      private def expect(token : String) : Nil
        raise ::IO::Error.new("Expected #{token}") unless consume(token)
      end
    end

    private def self.populate_from_xfdf_root(fdf : FDFDictionary, root : XML::Node) : Nil
      root.children.each do |child|
        next unless child.element?

        case child.name
        when "f"
          fdf.file = child["href"]?
        when "ids"
          ids = [] of String
          ids << child["original"]?.to_s if child["original"]?
          ids << child["modified"]?.to_s if child["modified"]?
          fdf.id = ids unless ids.empty?
        when "fields"
          fields = [] of FDFField
          child.children.each do |field_node|
            next unless field_node.element? && field_node.name == "field"
            fields << FDFField.from_xfdf(field_node)
          end
          fdf.fields = fields unless fields.empty?
        end
      end
    end
  end
end
