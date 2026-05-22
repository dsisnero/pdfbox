require "../../../../../spec_helper"

describe Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder do
  it "creates with valid parameters and computes matrix" do
    # Create the dependency chain: Cos::Dictionary -> PDAppearanceStream -> PDAppearanceContentStream
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new.tap { |a|
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(100)
      a << Pdfbox::Cos::Integer.new(100)
    }
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(dict)
    content_stream = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)

    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 100.0_f32, 200.0_f32)
    border = Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder.new(
      content_stream, 0.0, 1.0, rect
    )

    border.should_not be_nil
  end

  it "creates cloudy rectangle with zero intensity (plain rect)" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new.tap { |a|
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(100)
      a << Pdfbox::Cos::Integer.new(100)
    }
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(dict)
    content_stream = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)

    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 100.0_f32, 100.0_f32)
    border = Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder.new(
      content_stream, 0.0, 1.0, rect
    )

    # Zero intensity should produce a plain rectangle without crashing
    rd = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32)
    border.create_cloudy_rectangle(rd)

    # Verify rectangle was computed
    bbox = border.rectangle
    bbox.should_not be_nil
  end

  it "returns translation matrix" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new.tap { |a|
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(100)
      a << Pdfbox::Cos::Integer.new(100)
    }
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(dict)
    content_stream = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)

    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 100.0_f32, 100.0_f32)
    border = Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder.new(
      content_stream, 0.0, 1.0, rect
    )

    # Even with zero border, matrix should be identity translation (0,0)
    matrix = border.matrix
    matrix.translate_x.should eq(0.0_f32)
    matrix.translate_y.should eq(0.0_f32)
  end

  it "creates with non-zero intensity without crashing" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new.tap { |a|
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(200)
      a << Pdfbox::Cos::Integer.new(200)
    }
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(dict)
    content_stream = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)

    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 100.0_f32, 100.0_f32)
    border = Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder.new(
      content_stream, 2.0, 3.0, rect
    )
    border.should_not be_nil
  end

  it "computes rect_difference" do
    dict = Pdfbox::Cos::Dictionary.new
    dict[Pdfbox::Cos::Name.new("BBox")] = Pdfbox::Cos::Array.new.tap { |a|
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(0)
      a << Pdfbox::Cos::Integer.new(200)
      a << Pdfbox::Cos::Integer.new(200)
    }
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(dict)
    content_stream = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream)

    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 100.0_f32, 100.0_f32)
    border = Pdfbox::Pdmodel::Interactive::Annotation::Handlers::CloudyBorder.new(
      content_stream, 0.0, 2.0, rect
    )

    rd = border.rect_difference
    rd.should_not be_nil
  end
end
