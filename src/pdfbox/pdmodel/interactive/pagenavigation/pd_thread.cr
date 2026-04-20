module Pdfbox::Pdmodel::Interactive::Pagenavigation
  class PDThread
    @thread : Pdfbox::Cos::Dictionary

    def initialize(thread : Pdfbox::Cos::Dictionary)
      @thread = thread
    end

    def initialize
      @thread = Pdfbox::Cos::Dictionary.new
      @thread.set_item(Pdfbox::Cos::Name.new("Type"), Pdfbox::Cos::Name.new("Thread"))
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @thread
    end

    def thread_info : Pdfbox::Pdmodel::DocumentInformation?
      info = @thread[Pdfbox::Cos::Name.new("I")]?.as?(Pdfbox::Cos::Dictionary)
      info ? Pdfbox::Pdmodel::DocumentInformation.new(info) : nil
    end

    def thread_info=(info : Pdfbox::Pdmodel::DocumentInformation?) : Pdfbox::Pdmodel::DocumentInformation?
      if info
        @thread.set_item(Pdfbox::Cos::Name.new("I"), info.cos_object)
      else
        @thread.delete(Pdfbox::Cos::Name.new("I"))
      end
      info
    end

    def first_bead : PDThreadBead?
      bead = @thread[Pdfbox::Cos::Name.new("F")]?.as?(Pdfbox::Cos::Dictionary)
      bead ? PDThreadBead.new(bead) : nil
    end

    def first_bead=(bead : PDThreadBead?) : PDThreadBead?
      bead.try(&.thread = self)
      if bead
        @thread.set_item(Pdfbox::Cos::Name.new("F"), bead.cos_object)
      else
        @thread.delete(Pdfbox::Cos::Name.new("F"))
      end
      bead
    end
  end
end
