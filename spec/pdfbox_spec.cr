require "./spec_helper"

describe Pdfbox do
  it "has a version number" do
    Pdfbox::VERSION.should eq("0.1.0")
  end

  it "defines error classes" do
    Pdfbox::Error.should_not be_nil
    Pdfbox::PDFError.should_not be_nil
    Pdfbox::UnsupportedFeatureError.should_not be_nil
  end
end

describe Pdfbox::Cos do
  it "defines Boolean class" do
    Pdfbox::Cos::Boolean.should_not be_nil
  end

  it "defines Integer class" do
    Pdfbox::Cos::Integer.should_not be_nil
  end

  it "defines Float class" do
    Pdfbox::Cos::Float.should_not be_nil
  end

  it "defines String class" do
    Pdfbox::Cos::String.should_not be_nil
  end

  it "defines Name class" do
    Pdfbox::Cos::Name.should_not be_nil
  end

  it "defines Array class" do
    Pdfbox::Cos::Array.should_not be_nil
  end

  it "defines Dictionary class" do
    Pdfbox::Cos::Dictionary.should_not be_nil
  end

  it "defines Stream class" do
    Pdfbox::Cos::Stream.should_not be_nil
  end

  it "defines Object class" do
    Pdfbox::Cos::Object.should_not be_nil
  end

  describe Pdfbox::Cos::Boolean do
    it "has true and false constants" do
      Pdfbox::Cos::Boolean::TRUE.should_not be_nil
      Pdfbox::Cos::Boolean::FALSE.should_not be_nil
    end

    it "returns correct values" do
      Pdfbox::Cos::Boolean::TRUE.value.should be_true
      Pdfbox::Cos::Boolean::FALSE.value.should be_false
    end

    it "gets boolean via get method" do
      Pdfbox::Cos::Boolean.get(true).should eq(Pdfbox::Cos::Boolean::TRUE)
      Pdfbox::Cos::Boolean.get(false).should eq(Pdfbox::Cos::Boolean::FALSE)
    end
  end
end

describe Pdfbox::Pdmodel do
  it "defines Document class" do
    Pdfbox::Pdmodel::Document.should_not be_nil
  end

  it "defines Page class" do
    Pdfbox::Pdmodel::Page.should_not be_nil
  end

  it "defines Rectangle class" do
    Pdfbox::Pdmodel::Rectangle.should_not be_nil
  end

  describe Pdfbox::Pdmodel::Document do
    it "can be created" do
      doc = Pdfbox::Pdmodel::Document.new
      doc.should_not be_nil
    end

    it "can load (placeholder)" do
      # Create a minimal PDF in memory
      io = IO::Memory.new
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)
      doc.save(io)

      # Load it back
      loaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(io.to_s))
      loaded.should_not be_nil
      loaded.page_count.should eq(1)
    end

    it "can create new (placeholder)" do
      doc = Pdfbox::Pdmodel::Document.create
      doc.should_not be_nil
    end
  end
end

describe Pdfbox::IO do
  it "defines Utils module" do
    Pdfbox::IO::Utils.should_not be_nil
  end

  it "defines RandomAccessRead class" do
    Pdfbox::IO::RandomAccessRead.should_not be_nil
  end

  it "defines MemoryRandomAccessRead class" do
    Pdfbox::IO::MemoryRandomAccessRead.should_not be_nil
  end

  it "defines FileRandomAccessRead class" do
    Pdfbox::IO::FileRandomAccessRead.should_not be_nil
  end
end
