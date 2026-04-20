module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationMarkup < PDAnnotation
    RT_REPLY = "R"
    RT_GROUP = "Group"

    def title_popup : String?
      cos_object.get_string(Cos::Name.new("T"))
    end

    def border_style : PDBorderStyleDictionary?
      cos_object.get_dictionary(Cos::Name.new("BS")).try { |entry| PDBorderStyleDictionary.new(entry) }
    end

    def border_style=(value : PDBorderStyleDictionary) : PDBorderStyleDictionary
      cos_object[Cos::Name.new("BS")] = value.cos_object
      value
    end

    def title_popup=(value : String) : String
      cos_object.set_string(Cos::Name.new("T"), value)
      value
    end

    def popup : PDAnnotationPopup?
      cos_object.get_dictionary(Cos::Name.new("Popup")).try { |entry| PDAnnotationPopup.new(entry) }
    end

    def popup=(value : PDAnnotationPopup) : PDAnnotationPopup
      cos_object[Cos::Name.new("Popup")] = value.cos_object
      value
    end

    def constant_opacity : Float64
      cos_object.get_float(Cos::Name.new("CA"), 1.0_f64)
    end

    def constant_opacity=(value : Number) : Float64
      float_value = value.to_f64
      cos_object.set_float(Cos::Name.new("CA"), float_value)
      float_value
    end

    def rich_contents : String?
      case base = dereference(cos_object[Cos::Name.new("RC")]?)
      when Cos::String
        base.value
      when Cos::Stream
        String.new(base.create_input_stream.getb_to_end)
      end
    end

    def rich_contents=(value : String) : String
      cos_object[Cos::Name.new("RC")] = Cos::String.new(value)
      value
    end

    def creation_date : Time?
      cos_object.get_date(Cos::Name.new("CreationDate"))
    end

    def creation_date=(value : Time) : Time
      cos_object.set_date(Cos::Name.new("CreationDate"), value)
      value
    end

    def in_reply_to : PDAnnotation?
      cos_object.get_dictionary(Cos::Name.new("IRT")).try { |entry| PDAnnotation.create_annotation(entry) }
    rescue ::IO::Error
      nil
    end

    def in_reply_to=(value : PDAnnotation) : PDAnnotation
      cos_object[Cos::Name.new("IRT")] = value.cos_object
      value
    end

    def subject : String?
      cos_object.get_string(Cos::Name.new("Subj"))
    end

    def subject=(value : String) : String
      cos_object.set_string(Cos::Name.new("Subj"), value)
      value
    end

    def reply_type : String
      cos_object.get_name_as_string(Cos::Name.new("RT")) || RT_REPLY
    end

    def reply_type=(value : String) : String
      cos_object.set_name(Cos::Name.new("RT"), value)
      value
    end

    def intent : String?
      cos_object.get_name_as_string(Cos::Name.new("IT"))
    end

    def intent=(value : String) : String
      cos_object.set_name(Cos::Name.new("IT"), value)
      value
    end

    def external_data : PDExternalDataDictionary?
      cos_object.get_dictionary(Cos::Name.new("ExData")).try { |entry| PDExternalDataDictionary.new(entry) }
    end

    def external_data=(value : PDExternalDataDictionary) : PDExternalDataDictionary
      cos_object[Cos::Name.new("ExData")] = value.cos_object
      value
    end
  end
end
