module Pdfbox::Pdmodel::Interactive::Action
  class PDActionSound < PDAction
    SUB_TYPE = "Sound"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def sound : Cos::Stream?
      cos_object.get_stream(Cos::Name.new("Sound"))
    end

    def sound=(stream : Cos::Stream) : Cos::Stream
      cos_object[Cos::Name.new("Sound")] = stream
      stream
    end

    def volume : Float64
      current = cos_object.get_float(Cos::Name.new("Volume"), 1.0_f64)
      current < -1.0_f64 || current > 1.0_f64 ? 1.0_f64 : current
    end

    def volume=(value : Number) : Float64
      float_value = value.to_f64
      unless (-1.0_f64..1.0_f64).includes?(float_value)
        raise ArgumentError.new("volume outside of the range -1.0 to 1.0")
      end

      cos_object.set_float("Volume", float_value)
      float_value
    end

    def synchronous : Bool
      cos_object[Cos::Name.new("Synchronous")]?.as?(Cos::Boolean).try(&.value) || false
    end

    def synchronous=(value : Bool) : Bool
      cos_object.set_boolean("Synchronous", value)
      value
    end

    def repeat : Bool
      cos_object[Cos::Name.new("Repeat")]?.as?(Cos::Boolean).try(&.value) || false
    end

    def repeat=(value : Bool) : Bool
      cos_object.set_boolean("Repeat", value)
      value
    end

    def mix : Bool
      cos_object[Cos::Name.new("Mix")]?.as?(Cos::Boolean).try(&.value) || false
    end

    def mix=(value : Bool) : Bool
      cos_object.set_boolean("Mix", value)
      value
    end
  end
end
