module Pdfbox::Pdmodel
  # A name object specifying how the document shall be displayed when opened.
  enum PageMode
    USE_NONE
    USE_OUTLINES
    USE_THUMBS
    FULL_SCREEN
    USE_OPTIONAL_CONTENT
    USE_ATTACHMENTS

    def self.from_string(value : String) : self
      case value
      when "UseNone"        then USE_NONE
      when "UseOutlines"    then USE_OUTLINES
      when "UseThumbs"      then USE_THUMBS
      when "FullScreen"     then FULL_SCREEN
      when "UseOC"          then USE_OPTIONAL_CONTENT
      when "UseAttachments" then USE_ATTACHMENTS
      else
        raise ArgumentError.new(value)
      end
    end

    def string_value : String
      case self
      when .use_none?             then "UseNone"
      when .use_outlines?         then "UseOutlines"
      when .use_thumbs?           then "UseThumbs"
      when .full_screen?          then "FullScreen"
      when .use_optional_content? then "UseOC"
      when .use_attachments?      then "UseAttachments"
      else
        raise ArgumentError.new(to_s)
      end
    end
  end
end
