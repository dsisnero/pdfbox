module Pdfbox::Pdmodel::Interactive::Pagenavigation
  enum PDTransitionDimension
    H
    V
  end

  enum PDTransitionMotion
    I
    O
  end

  enum PDTransitionStyle
    Split
    Blinds
    Box
    Wipe
    Dissolve
    Glitter
    R
    Fly
    Push
    Cover
    Uncover
    Fade
  end

  class PDTransitionDirection
    getter cos_base

    LEFT_TO_RIGHT            = new(Pdfbox::Cos::Integer.new(0))
    BOTTOM_TO_TOP            = new(Pdfbox::Cos::Integer.new(90))
    RIGHT_TO_LEFT            = new(Pdfbox::Cos::Integer.new(180))
    TOP_TO_BOTTOM            = new(Pdfbox::Cos::Integer.new(270))
    TOP_LEFT_TO_BOTTOM_RIGHT = new(Pdfbox::Cos::Integer.new(315))
    NONE                     = new(Pdfbox::Cos::Name.new("None"))

    def initialize(@cos_base : Pdfbox::Cos::Base)
    end

    def ==(other : self) : Bool
      @cos_base == other.cos_base
    end
  end

  class PDTransition
    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      initialize(PDTransitionStyle::R)
    end

    def initialize(style : PDTransitionStyle)
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name(Pdfbox::Cos::Name.new("Type"), "Trans")
      @dictionary.set_name(Pdfbox::Cos::Name.new("S"), style.to_s)
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def style : String
      @dictionary.get_name_as_string(Pdfbox::Cos::Name.new("S")) || PDTransitionStyle::R.to_s
    end

    def dimension : String
      @dictionary.get_name_as_string(Pdfbox::Cos::Name.new("Dm")) || PDTransitionDimension::H.to_s
    end

    def dimension=(dimension : PDTransitionDimension) : PDTransitionDimension
      @dictionary.set_name(Pdfbox::Cos::Name.new("Dm"), dimension.to_s)
      dimension
    end

    def motion : String
      @dictionary.get_name_as_string(Pdfbox::Cos::Name.new("M")) || PDTransitionMotion::I.to_s
    end

    def motion=(motion : PDTransitionMotion) : PDTransitionMotion
      @dictionary.set_name(Pdfbox::Cos::Name.new("M"), motion.to_s)
      motion
    end

    def direction : Pdfbox::Cos::Base
      @dictionary[Pdfbox::Cos::Name.new("Di")]? || Pdfbox::Cos::Integer.new(0)
    end

    def direction=(direction : PDTransitionDirection) : PDTransitionDirection
      @dictionary.set_item(Pdfbox::Cos::Name.new("Di"), direction.cos_base)
      direction
    end

    def duration : Float64
      @dictionary.get_float(Pdfbox::Cos::Name.new("D"), 1.0_f64)
    end

    def duration=(duration : Float64) : Float64
      @dictionary.set_float(Pdfbox::Cos::Name.new("D"), duration)
      duration
    end

    def fly_scale : Float64
      @dictionary.get_float(Pdfbox::Cos::Name.new("SS"), 1.0_f64)
    end

    def fly_scale=(scale : Float64) : Float64
      @dictionary.set_float(Pdfbox::Cos::Name.new("SS"), scale)
      scale
    end

    def fly_area_opaque? : Bool
      @dictionary[Pdfbox::Cos::Name.new("B")]?.as?(Pdfbox::Cos::Boolean).try(&.value) || false
    end

    def fly_area_opaque=(opaque : Bool) : Bool
      @dictionary.set_item(Pdfbox::Cos::Name.new("B"), Pdfbox::Cos::Boolean.get(opaque))
      opaque
    end
  end
end
