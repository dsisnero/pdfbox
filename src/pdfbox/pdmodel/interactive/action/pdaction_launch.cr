module Pdfbox::Pdmodel::Interactive::Action
  class PDActionLaunch < PDAction
    SUB_TYPE = "Launch"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def file : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification?
      Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(cos_object[Cos::Name.new("F")]?)
    end

    def file=(fs : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification) : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification
      cos_object[Cos::Name.new("F")] = fs.cos_object
      fs
    end

    def win_launch_params : PDWindowsLaunchParams?
      cos_object[Cos::Name.new("Win")]?.as?(Cos::Dictionary).try { |dict| PDWindowsLaunchParams.new(dict) }
    end

    def win_launch_params=(win : PDWindowsLaunchParams) : PDWindowsLaunchParams
      cos_object[Cos::Name.new("Win")] = win.cos_object
      win
    end

    def f : String?
      cos_object.get_string(Cos::Name.new("F"))
    end

    def f=(value : String) : String
      cos_object.set_string("F", value)
      value
    end

    def d : String?
      cos_object.get_string(Cos::Name.new("D"))
    end

    def d=(value : String) : String
      cos_object.set_string("D", value)
      value
    end

    def o : String?
      cos_object.get_string(Cos::Name.new("O"))
    end

    def o=(value : String) : String
      cos_object.set_string("O", value)
      value
    end

    def p : String?
      cos_object.get_string(Cos::Name.new("P"))
    end

    def p=(value : String) : String
      cos_object.set_string("P", value)
      value
    end

    def open_in_new_window : OpenMode
      value = cos_object[Cos::Name.new("NewWindow")]?
      if bool = value.as?(Cos::Boolean)
        bool.value ? OpenMode::NewWindow : OpenMode::SameWindow
      else
        OpenMode::UserPreference
      end
    end

    def open_in_new_window=(value : OpenMode) : OpenMode
      case value
      when .user_preference?
        cos_object.delete(Cos::Name.new("NewWindow"))
      when .same_window?
        cos_object.set_boolean("NewWindow", false)
      when .new_window?
        cos_object.set_boolean("NewWindow", true)
      end
      value
    end
  end
end
