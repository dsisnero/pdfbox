module Pdfbox::Pdmodel::Interactive::Pagenavigation
  class PDThreadBead
    @bead : Pdfbox::Cos::Dictionary

    def initialize(bead : Pdfbox::Cos::Dictionary)
      @bead = bead
    end

    def initialize
      @bead = Pdfbox::Cos::Dictionary.new
      @bead.set_item(Pdfbox::Cos::Name.new("Type"), Pdfbox::Cos::Name.new("Bead"))
      set_next_bead(self)
      set_previous_bead(self)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @bead
    end

    def thread : PDThread?
      dictionary = @bead[Pdfbox::Cos::Name.new("T")]?.as?(Pdfbox::Cos::Dictionary)
      dictionary ? PDThread.new(dictionary) : nil
    end

    def thread=(thread : PDThread?) : PDThread?
      if thread
        @bead.set_item(Pdfbox::Cos::Name.new("T"), thread.cos_object)
      else
        @bead.delete(Pdfbox::Cos::Name.new("T"))
      end
      thread
    end

    def next_bead : PDThreadBead
      PDThreadBead.new(@bead[Pdfbox::Cos::Name.new("N")].as(Pdfbox::Cos::Dictionary))
    end

    def previous_bead : PDThreadBead
      PDThreadBead.new(@bead[Pdfbox::Cos::Name.new("V")].as(Pdfbox::Cos::Dictionary))
    end

    def append_bead(append : PDThreadBead) : PDThreadBead
      next_bead = self.next_bead
      next_bead.set_previous_bead(append)
      append.set_next_bead(next_bead)
      set_next_bead(append)
      append.set_previous_bead(self)
      append
    end

    def page : Pdfbox::Pdmodel::Page?
      dictionary = @bead[Pdfbox::Cos::Name.new("P")]?.as?(Pdfbox::Cos::Dictionary)
      dictionary ? Pdfbox::Pdmodel::Page.new(dictionary) : nil
    end

    def page=(page : Pdfbox::Pdmodel::Page?) : Pdfbox::Pdmodel::Page?
      if cos_page = page.try(&.cos_object)
        @bead.set_item(Pdfbox::Cos::Name.new("P"), cos_page)
      else
        @bead.delete(Pdfbox::Cos::Name.new("P"))
      end
      page
    end

    def rectangle : Pdfbox::Pdmodel::Common::PDRectangle?
      array = @bead[Pdfbox::Cos::Name.new("R")]?.as?(Pdfbox::Cos::Array)
      array ? Pdfbox::Pdmodel::Common::PDRectangle.new(array) : nil
    end

    def rectangle=(rectangle : Pdfbox::Pdmodel::Common::PDRectangle?) : Pdfbox::Pdmodel::Common::PDRectangle?
      if rectangle
        @bead.set_item(Pdfbox::Cos::Name.new("R"), rectangle.cos_object)
      else
        @bead.delete(Pdfbox::Cos::Name.new("R"))
      end
      rectangle
    end

    protected def set_next_bead(next_bead : PDThreadBead) : PDThreadBead
      @bead.set_item(Pdfbox::Cos::Name.new("N"), next_bead.cos_object)
      next_bead
    end

    protected def set_previous_bead(previous_bead : PDThreadBead) : PDThreadBead
      @bead.set_item(Pdfbox::Cos::Name.new("V"), previous_bead.cos_object)
      previous_bead
    end
  end
end
