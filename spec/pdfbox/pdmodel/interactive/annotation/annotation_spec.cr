require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private class TestAnnotationFilter
  include Pdfbox::Pdmodel::Interactive::Annotation::AnnotationFilter

  def accept(candidate : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation) : Bool
    candidate.printed?
  end
end

private class TestAppearanceHandler
  include Pdfbox::Pdmodel::Interactive::Annotation::Handlers::PDAppearanceHandler

  getter events

  def initialize
    @events = [] of String
  end

  def generate_normal_appearance : Nil
    @events << "normal"
  end

  def generate_rollover_appearance : Nil
    @events << "rollover"
  end

  def generate_down_appearance : Nil
    @events << "down"
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation do
  it "creates typed annotations from subtype dictionaries" do
    file_attachment_dict = Pdfbox::Cos::Dictionary.new
    file_attachment_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "FileAttachment")
    line_dict = Pdfbox::Cos::Dictionary.new
    line_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Line")
    widget_dict = Pdfbox::Cos::Dictionary.new
    widget_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Widget")
    free_text_dict = Pdfbox::Cos::Dictionary.new
    free_text_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "FreeText")
    caret_dict = Pdfbox::Cos::Dictionary.new
    caret_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Caret")
    stamp_dict = Pdfbox::Cos::Dictionary.new
    stamp_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Stamp")
    polygon_dict = Pdfbox::Cos::Dictionary.new
    polygon_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Polygon")
    polyline_dict = Pdfbox::Cos::Dictionary.new
    polyline_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "PolyLine")
    ink_dict = Pdfbox::Cos::Dictionary.new
    ink_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Ink")
    text_dict = Pdfbox::Cos::Dictionary.new
    text_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Text")
    sound_dict = Pdfbox::Cos::Dictionary.new
    sound_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Sound")
    popup_dict = Pdfbox::Cos::Dictionary.new
    popup_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Popup")
    underline_dict = Pdfbox::Cos::Dictionary.new
    underline_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Underline")
    strikeout_dict = Pdfbox::Cos::Dictionary.new
    strikeout_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "StrikeOut")
    squiggly_dict = Pdfbox::Cos::Dictionary.new
    squiggly_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "Squiggly")
    unknown_dict = Pdfbox::Cos::Dictionary.new
    unknown_dict.set_name(Pdfbox::Cos::Name::SUBTYPE, "UnknownSubtype")

    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(file_attachment_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(line_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(widget_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(free_text_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFreeText)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(caret_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCaret)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(stamp_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationRubberStamp)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(polygon_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolygon)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(polyline_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolyline)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(ink_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationInk)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(text_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(sound_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSound)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(popup_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(underline_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationUnderline)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(strikeout_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationStrikeout)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(squiggly_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquiggly)
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(unknown_dict)
      .should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationUnknown)

    expect_raises(IO::Error, /Unknown annotation type/) do
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(Pdfbox::Cos::String.new("bad"))
    end
  end

  it "stores rectangle, flags, metadata, color, page, optional content, and appearance" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(1.0_f32, 2.0_f32, 30.0_f32, 40.0_f32)
    border = Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(1), Pdfbox::Cos::Integer.new(2)])
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.1_f32, 0.2_f32, 0.3_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    page = Pdfbox::Pdmodel::Page.new
    property_list = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.new(Pdfbox::Cos::Dictionary.new)
    appearance_stream = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceStream.new(Pdfbox::Cos::Stream.new)
    appearance_dict = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
    appearance_dict.normal_appearance = appearance_stream

    widget.rectangle = rect
    widget.annotation_flags = 3
    widget.printed = true
    widget.no_zoom = true
    widget.no_rotate = true
    widget.no_view = true
    widget.read_only = true
    widget.locked = true
    widget.toggle_no_view = true
    widget.locked_contents = true
    widget.contents = "note"
    widget.modified_date = "D:20260405010101Z"
    widget.annotation_name = "Annot-1"
    widget.struct_parent = 7
    widget.border = border
    widget.color = color
    widget.page = page
    widget.optional_content = property_list
    widget.appearance_state = "On"
    widget.appearance = appearance_dict

    widget.cos_object[Pdfbox::Cos::Name::TYPE].should eq(Pdfbox::Cos::Name.new("Annot"))
    widget.rectangle.not_nil!.width.should eq(30.0_f32)
    widget.flags.should eq(1023)
    widget.invisible?.should be_true
    widget.hidden?.should be_true
    widget.printed?.should be_true
    widget.no_zoom?.should be_true
    widget.no_rotate?.should be_true
    widget.no_view?.should be_true
    widget.read_only?.should be_true
    widget.locked?.should be_true
    widget.toggle_no_view?.should be_true
    widget.locked_contents?.should be_true
    widget.contents.should eq("note")
    widget.modified_date.should eq("D:20260405010101Z")
    widget.annotation_name.should eq("Annot-1")
    widget.struct_parent.should eq(7)
    widget.border.size.should eq(3)
    widget.border.get_int(0).should eq(1)
    widget.border.get_int(1).should eq(2)
    widget.border.get_int(2).should eq(0)
    widget.color.not_nil!.components.should eq([0.1_f32, 0.2_f32, 0.3_f32])
    widget.page.not_nil!.cos_object.should eq(page.cos_object)
    widget.optional_content.not_nil!.cos_object.should eq(property_list.cos_object)
    widget.appearance_state.should eq(Pdfbox::Cos::Name.new("On"))
    widget.normal_appearance_stream.not_nil!.cos_object.should eq(appearance_stream.cos_object)
  end

  it "returns nil for invalid rectangles and synthesizes the default border" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    widget.cos_object[Pdfbox::Cos::Name.new("Rect")] = Pdfbox::Cos::Array.new([Pdfbox::Cos::String.new("bad")])

    widget.rectangle.should be_nil
    widget.border.get_int(0).should eq(0)
    widget.border.get_int(1).should eq(0)
    widget.border.get_int(2).should eq(1)
  end

  it "resolves normal appearance streams through subdictionaries" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    appearance_state = "Checked"
    widget.appearance_state = appearance_state

    stream_dict = Pdfbox::Cos::Dictionary.new
    normal_dict = Pdfbox::Cos::Dictionary.new
    normal_dict[Pdfbox::Cos::Name.new(appearance_state)] = stream_dict
    appearance_cos = Pdfbox::Cos::Dictionary.new
    appearance_cos[Pdfbox::Cos::Name.new("N")] = normal_dict
    widget.appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new(appearance_cos)

    widget.normal_appearance_stream.not_nil!.cos_object.should eq(stream_dict)
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::Handlers::PDAppearanceHandler do
  it "runs normal, rollover, and down generation in order" do
    handler = TestAppearanceHandler.new

    handler.generate_appearance_streams

    handler.events.should eq(["normal", "rollover", "down"])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget do
  it "stores widget-specific field name, actions, appearance, border style, parent, and raw page reference" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    page_ref = Pdfbox::Cos::Dictionary.new
    appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    actions = Pdfbox::Pdmodel::Interactive::Action::PDAnnotationAdditionalActions.new
    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(Pdfbox::Pdmodel::Document.new)
    field_dict = Pdfbox::Cos::Dictionary.new
    parent_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, field_dict, nil)

    appearance.rotation = 180
    border_style.width = 3
    action.uri = "https://example.com/widget"
    actions.e = action
    widget.highlighting_mode = "T"
    widget.appearance_characteristics = appearance
    widget.action = action
    widget.actions = actions
    widget.border_style = border_style
    widget.field_name = "TestField"
    widget.page_ref = page_ref
    widget.parent = parent_field

    widget.subtype.should eq("Widget")
    widget.highlighting_mode.should eq("T")
    widget.appearance_characteristics.not_nil!.rotation.should eq(180)
    widget.action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    widget.actions.not_nil!.e.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    widget.border_style.not_nil!.width.should eq(3.0)
    widget.field_name.should eq("TestField")
    widget.page_ref.should eq(page_ref)
    widget.cos_object.get_dictionary(Pdfbox::Cos::Name.new("Parent")).should eq(field_dict)
  end
end

describe "annotation appearance handler support" do
  it "delegates custom appearance generation for square, circle, text, and link annotations" do
    square = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
    circle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new
    text = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new

    square_handler = TestAppearanceHandler.new
    circle_handler = TestAppearanceHandler.new
    text_handler = TestAppearanceHandler.new
    link_handler = TestAppearanceHandler.new

    square.custom_appearance_handler = square_handler
    circle.custom_appearance_handler = circle_handler
    text.custom_appearance_handler = text_handler
    link.custom_appearance_handler = link_handler

    square.construct_appearances
    circle.construct_appearances(Pdfbox::Pdmodel::Document.new)
    text.construct_appearances
    link.construct_appearances

    square_handler.events.should eq(["normal", "rollover", "down"])
    circle_handler.events.should eq(["normal", "rollover", "down"])
    text_handler.events.should eq(["normal", "rollover", "down"])
    link_handler.events.should eq(["normal", "rollover", "down"])
  end

  it "keeps construct_appearances as a no-op when no custom handler is set" do
    square = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
    square.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 40.0_f32)
    square.construct_appearances
    square.normal_appearance_stream.should_not be_nil
  end
end

describe "default square and circle appearance handlers" do
  it "builds a square appearance stream with bbox, matrix, and stroke operators" do
    square = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(91.5958_f32, 741.91_f32, 22.2532_f32, 15.168_f32)

    border_style.width = 1
    square.color = color
    square.border_style = border_style
    square.rectangle = rectangle
    square.construct_appearances

    appearance = square.normal_appearance_stream.not_nil!
    appearance.bbox.not_nil!.lower_left_x.should eq(rectangle.lower_left_x)
    appearance.bbox.not_nil!.lower_left_y.should eq(rectangle.lower_left_y)
    appearance.bbox.not_nil!.width.should eq(rectangle.width)
    appearance.bbox.not_nil!.height.should eq(rectangle.height)
    appearance.matrix.get_value(2, 0).should eq(-rectangle.lower_left_x)
    appearance.matrix.get_value(2, 1).should eq(-rectangle.lower_left_y)

    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 0 0 RG")
    content.should contain("1 w")
    content.should contain("92.5958")
    content.should contain("20.2532")
    content.should contain("re")
    content.should contain("S")
  end

  it "builds a circle appearance stream with bezier curve operators" do
    circle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

    border_style.width = 2
    circle.color = color
    circle.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 40.0_f32)
    circle.border_style = border_style
    circle.construct_appearances

    appearance = circle.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0 0 1 RG")
    content.should contain("2 w")
    content.should contain("m")
    content.should contain("c")
    content.should contain("h")
    content.should contain("S")
  end
end

describe "text markup appearance handlers" do
  it "builds an underline appearance stream with stroke operators" do
    underline = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationUnderline.new
    underline.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    underline.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 40.0_f32, 20.0_f32)
    underline.quad_points = [10, 30, 50, 30, 10, 10, 50, 10]

    underline.construct_appearances

    appearance = underline.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 0 0 RG")
    content.should contain("1 w")
    content.should contain("m")
    content.should contain("l")
    content.should contain("S")
  end

  it "builds a strikeout appearance stream across the quad midpoint" do
    strikeout = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationStrikeout.new
    strikeout.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    strikeout.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 40.0_f32, 20.0_f32)
    strikeout.quad_points = [10, 30, 50, 30, 10, 10, 50, 10]

    strikeout.construct_appearances

    appearance = strikeout.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0 0 1 RG")
    content.should contain("1 w")
    content.should contain("m")
    content.should contain("l")
    content.should contain("S")
  end

  it "builds a highlight appearance stream with filled quad paths" do
    highlight = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    highlight.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    highlight.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 40.0_f32, 20.0_f32)
    highlight.quad_points = [10, 30, 50, 30, 10, 10, 50, 10]

    highlight.construct_appearances

    appearance = highlight.normal_appearance_stream.not_nil!
    resources = appearance.resources.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    resources.ext_g_state_names.map(&.value).should eq(["gs1", "gs2"])
    resources.xobject_names.map(&.value).should eq(["Fm1"])
    content.should contain("/gs1 gs")
    content.should contain("/gs2 gs")
    content.should contain("/Fm1 Do")

    form1_stream = resources.cos_object.not_nil!
      .get_dictionary(Pdfbox::Cos::Name.new("XObject")).as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fm1")].as(Pdfbox::Cos::Stream)
    form1 = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(form1_stream)
    form1.group.should_not be_nil
    form1.resources.not_nil!.xobject_names.map(&.value).should eq(["Fm1"])
    String.new(form1.content_stream.create_input_stream.getb_to_end).should contain("/Fm1 Do")

    form2_stream = form1.resources.not_nil!.cos_object.as(Pdfbox::Cos::Dictionary)
      .get_dictionary(Pdfbox::Cos::Name.new("XObject")).as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fm1")].as(Pdfbox::Cos::Stream)
    form2 = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(form2_stream)
    form2_content = String.new(form2.content_stream.create_input_stream.getb_to_end)
    form2_content.should contain("1 1 0 rg")
    form2_content.should contain("m")
    form2_content.should contain("f")
  end

  it "builds a squiggly appearance stream with nested form and pattern resources" do
    squiggly = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquiggly.new
    squiggly.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    squiggly.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 40.0_f32, 20.0_f32)
    squiggly.quad_points = [10, 30, 50, 30, 10, 10, 50, 10]

    squiggly.construct_appearances

    appearance = squiggly.normal_appearance_stream.not_nil!
    resources = appearance.resources.not_nil!
    resources.xobject_names.map(&.value).should eq(["Fm1"])

    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0.5 0 0 0.27778 10 10 cm")
    content.should contain("/Fm1 Do")

    form1_stream = resources.cos_object.not_nil!
      .get_dictionary(Pdfbox::Cos::Name.new("XObject")).as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Fm1")].as(Pdfbox::Cos::Stream)
    form1 = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(form1_stream)
    form1.resources.not_nil!.pattern_names.map(&.value).should eq(["Pattern1"])
    form1_content = String.new(form1.content_stream.create_input_stream.getb_to_end)
    form1_content.should contain("/Pattern1 scn")
    form1_content.should contain("re")
    form1_content.should contain("f")

    pattern_stream = form1.resources.not_nil!.cos_object.as(Pdfbox::Cos::Dictionary)
      .get_dictionary(Pdfbox::Cos::Name.new("Pattern")).as(Pdfbox::Cos::Dictionary)[Pdfbox::Cos::Name.new("Pattern1")].as(Pdfbox::Cos::Stream)
    pattern = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern.new(pattern_stream)
    pattern_content = String.new(pattern.content_stream.create_input_stream.getb_to_end)
    pattern_content.should contain("1 J")
    pattern_content.should contain("1 j")
    pattern_content.should contain("10 M")
    pattern_content.should contain("S")
  end
end

describe "ink and polygon appearance handlers" do
  it "builds an ink appearance stream with stroked paths" do
    ink = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationInk.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    ink.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    ink.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 30.0_f32, 20.0_f32)
    border_style.width = 2
    ink.border_style = border_style
    ink.ink_list = [[12, 14, 25, 18, 35, 24], [14, 12, 18, 11]]

    ink.construct_appearances

    appearance = ink.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0 0 0 RG")
    content.should contain("2 w")
    content.scan(/\bm\b/).size.should be >= 2
    content.scan(/\bl\b/).size.should be >= 2
    content.scan(/\bS\b/).size.should eq(2)
  end

  it "builds a polygon appearance stream from vertices with stroke and fill" do
    polygon = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolygon.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    polygon.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    polygon.interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    polygon.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 40.0_f32, 30.0_f32)
    border_style.width = 3
    polygon.border_style = border_style
    polygon.vertices = [10, 10, 30, 40, 50, 10]

    polygon.construct_appearances

    appearance = polygon.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 0 0 RG")
    content.should contain("0 1 0 rg")
    content.should contain("3 w")
    content.should contain("h")
    content.should contain("B")
  end

  it "builds a polygon appearance stream from PDF 2 path arrays" do
    polygon = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolygon.new
    polygon.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    polygon.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 20.0_f32, 20.0_f32)
    path = Pdfbox::Cos::Array.new
    path.add(Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(1), Pdfbox::Cos::Integer.new(2)]))
    path.add(Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(3), Pdfbox::Cos::Integer.new(4)]))
    path.add(Pdfbox::Cos::Array.new([
      Pdfbox::Cos::Integer.new(5), Pdfbox::Cos::Integer.new(6),
      Pdfbox::Cos::Integer.new(7), Pdfbox::Cos::Integer.new(8),
      Pdfbox::Cos::Integer.new(9), Pdfbox::Cos::Integer.new(10),
    ]))
    polygon.cos_object[Pdfbox::Cos::Name.new("Path")] = path

    polygon.construct_appearances

    content = String.new(polygon.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 2 m")
    content.should contain("3 4 l")
    content.should contain("5 6 7 8 9 10 c")
    content.should contain("h")
    content.should contain("S")
  end

  it "builds a polyline appearance stream with line endings" do
    polyline = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolyline.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    polyline.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    polyline.interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    polyline.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 20.0_f32, 10.0_f32)
    border_style.width = 2
    polyline.border_style = border_style
    polyline.start_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_OPEN_ARROW
    polyline.end_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_CLOSED_ARROW
    polyline.vertices = [10, 10, 20, 15, 30, 10]

    polyline.construct_appearances

    content = String.new(polyline.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 0 0 RG")
    content.should contain("0 1 0 rg")
    content.should contain("2 w")
    content.should contain("q")
    content.should contain("Q")
    content.should contain("cm")
    content.scan(/\bS\b/).size.should be >= 1
    content.scan(/\bB\b/).size.should be >= 1
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary do
  it "stores style and intensity" do
    border_effect = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary.new

    border_effect.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
    border_effect.intensity = 1.5

    border_effect.style.should eq("C")
    border_effect.intensity.should eq(1.5)
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary do
  it "stores width, style, and dash style defaults" do
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    dash_array = Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(2), Pdfbox::Cos::Integer.new(1)])

    border_style.width = 2
    border_style.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_DASHED
    border_style.dash_style = dash_array

    border_style.width.should eq(2.0)
    border_style.style.should eq("D")
    border_style.dash_style.dash_array.should eq([2.0, 1.0])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDExternalDataDictionary do
  it "stores subtype and defaults type to ExData" do
    external_data = Pdfbox::Pdmodel::Interactive::Annotation::PDExternalDataDictionary.new

    external_data.subtype = "Markup3D"

    external_data.type.should eq("ExData")
    external_data.subtype.should eq("Markup3D")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary do
  it "stores rotation, colors, and captions" do
    appearance = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
    border_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.1_f32, 0.2_f32, 0.3_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    background = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.6_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)

    appearance.rotation = 90
    appearance.border_colour = border_color
    appearance.background = background
    appearance.normal_caption = "Normal"
    appearance.rollover_caption = "Hover"
    appearance.alternate_caption = "Pressed"

    appearance.rotation.should eq(90)
    appearance.border_colour.not_nil!.components.should eq([0.1_f32, 0.2_f32, 0.3_f32])
    appearance.background.not_nil!.components.should eq([0.6_f32])
    appearance.normal_caption.should eq("Normal")
    appearance.rollover_caption.should eq("Hover")
    appearance.alternate_caption.should eq("Pressed")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationMarkup do
  it "stores common markup metadata, border style, and external data" do
    markup = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
    popup = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup.new
    parent = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    external_data = Pdfbox::Pdmodel::Interactive::Annotation::PDExternalDataDictionary.new
    now = Time.utc(2026, 4, 5, 12, 0, 0)

    border_style.width = 2
    external_data.subtype = "Markup3D"
    markup.title_popup = "Author"
    markup.border_style = border_style
    markup.popup = popup
    markup.constant_opacity = 0.4
    markup.rich_contents = "<body>rich</body>"
    markup.creation_date = now
    markup.in_reply_to = parent
    markup.subject = "Topic"
    markup.reply_type = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationMarkup::RT_GROUP
    markup.intent = "FreeTextTypeWriter"
    markup.external_data = external_data

    markup.title_popup.should eq("Author")
    markup.border_style.not_nil!.width.should eq(2.0)
    markup.popup.not_nil!.subtype.should eq("Popup")
    markup.constant_opacity.should eq(0.4)
    markup.rich_contents.should eq("<body>rich</body>")
    markup.creation_date.should eq(now)
    markup.in_reply_to.should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
    markup.subject.should eq("Topic")
    markup.reply_type.should eq("Group")
    markup.intent.should eq("FreeTextTypeWriter")
    markup.external_data.not_nil!.subtype.should eq("Markup3D")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink do
  it "stores action, border style, destination, highlight mode, previous uri, and quad points" do
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    previous_uri = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new(Pdfbox::Cos::String.new("Chapter1"))

    action.uri = "https://example.com/current"
    previous_uri.uri = "https://example.com/previous"
    border_style.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_UNDERLINE
    link.action = action
    link.border_style = border_style
    link.destination = destination
    link.highlight_mode = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink::HIGHLIGHT_MODE_PUSH
    link.previous_uri = previous_uri
    link.quad_points = [1, 2, 3, 4, 5, 6, 7, 8]

    link.subtype.should eq("Link")
    link.action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    link.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/current")
    link.border_style.not_nil!.style.should eq("U")
    link.destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination)
    link.highlight_mode.should eq("P")
    link.previous_uri.not_nil!.uri.should eq("https://example.com/previous")
    link.quad_points.should eq([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
  end

  it "builds a link appearance stream from quad points and underline style" do
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new

    link.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 10.0_f32)
    link.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    border_style.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary::STYLE_UNDERLINE
    border_style.width = 2
    link.border_style = border_style
    link.quad_points = [10, 20, 40, 20, 40, 30, 10, 30]

    link.construct_appearances

    appearance = link.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0 0 1 RG")
    content.should contain("2 w")
    content.should contain("10 20 m")
    content.should contain("40 20 l")
    content.should_not contain("h")
    content.should contain("S")
  end

  it "falls back to the padded rectangle when quad points lie outside the annotation rect" do
    link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new

    link.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 10.0_f32)
    link.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    border_style.width = 2
    link.border_style = border_style
    link.quad_points = [5, 20, 40, 20, 40, 30, 10, 30]

    link.construct_appearances

    appearance = link.normal_appearance_stream.not_nil!
    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 G")
    content.should contain("2 w")
    content.should contain("11 21 m")
    content.should contain("39 21 l")
    content.should contain("39 29 l")
    content.should contain("11 29 l")
    content.should contain("h")
    content.should contain("S")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment do
  it "stores attachment icon and file specification" do
    file_attachment = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment.new
    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDComplexFileSpecification.new

    file_spec.file = "attachment.txt"
    file_attachment.attachment_name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment::ATTACHMENT_NAME_TAG
    file_attachment.file = file_spec

    file_attachment.subtype.should eq("FileAttachment")
    file_attachment.attachment_name.should eq("Tag")
    file_attachment.file.not_nil!.file.should eq("attachment.txt")
  end

  it "builds the default pushpin appearance stream" do
    file_attachment = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment.new

    file_attachment.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 30.0_f32)

    file_attachment.construct_appearances

    appearance = file_attachment.normal_appearance_stream.not_nil!
    file_attachment.rectangle.not_nil!.width.should eq(18.0_f32)
    file_attachment.rectangle.not_nil!.height.should eq(18.0_f32)
    appearance.bbox.not_nil!.width.should eq(18.0_f32)
    appearance.bbox.not_nil!.height.should eq(18.0_f32)

    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("0.022 0 0 -0.022 0 18 cm")
    content.should contain("586.46997 178.97 cm")
    content.should contain("m")
    content.should contain("c")
    content.should contain("f")
  end

  it "builds the tag appearance stream" do
    file_attachment = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment.new

    file_attachment.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 18.0_f32, 18.0_f32, 18.0_f32)
    file_attachment.attachment_name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFileAttachment::ATTACHMENT_NAME_TAG

    file_attachment.construct_appearances

    content = String.new(file_attachment.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("q")
    content.should contain("Q")
    content.should contain("209.25999 128.32001 cm")
    content.should contain("382.22 79.91 cm")
    content.should contain("f")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCaret do
  it "stores caret rectangle differences" do
    caret = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCaret.new

    caret.rect_differences = [1, 2, 3, 4]

    caret.subtype.should eq("Caret")
    caret.rect_differences.should eq([1.0, 2.0, 3.0, 4.0])
  end

  it "builds a caret appearance stream and synthesizes rect differences when absent" do
    caret = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCaret.new

    caret.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 20.0_f32, 10.0_f32)
    caret.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

    caret.construct_appearances

    appearance = caret.normal_appearance_stream.not_nil!
    caret.rect_differences.should eq([1.0, 1.0, 1.0, 1.0])
    caret.rectangle.not_nil!.lower_left_x.should eq(9.0_f32)
    caret.rectangle.not_nil!.lower_left_y.should eq(19.0_f32)
    caret.rectangle.not_nil!.width.should eq(22.0_f32)
    caret.rectangle.not_nil!.height.should eq(12.0_f32)
    appearance.bbox.not_nil!.lower_left_x.should eq(-1.0_f32)
    appearance.bbox.not_nil!.lower_left_y.should eq(-1.0_f32)
    appearance.bbox.not_nil!.width.should eq(22.0_f32)
    appearance.bbox.not_nil!.height.should eq(12.0_f32)
    appearance.matrix.get_value(2, 0).should eq(-9.0_f32)
    appearance.matrix.get_value(2, 1).should eq(-19.0_f32)

    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 0 0 RG")
    content.should contain("1 0 0 rg")
    content.should contain("0 0 m")
    content.should contain("c")
    content.should contain("h")
    content.should contain("f")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFreeText do
  it "stores free text settings and callout geometry" do
    free_text = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationFreeText.new
    border_effect = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary.new
    rect_difference = Pdfbox::Pdmodel::Common::PDRectangle.new(1.0_f32, 2.0_f32, 3.0_f32, 4.0_f32)

    border_effect.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
    free_text.default_appearance = "/Helv 12 Tf 0 g"
    free_text.default_style_string = "font: Helvetica 12pt;"
    free_text.q = 2
    free_text.rect_differences = [1, 2, 3, 4]
    free_text.callout = [1, 2, 3, 4, 5, 6]
    free_text.line_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_OPEN_ARROW
    free_text.border_effect = border_effect
    free_text.rect_difference = rect_difference

    free_text.subtype.should eq("FreeText")
    free_text.default_appearance.should eq("/Helv 12 Tf 0 g")
    free_text.default_style_string.should eq("font: Helvetica 12pt;")
    free_text.q.should eq(2)
    free_text.callout.should eq([1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    free_text.line_ending_style.should eq("OpenArrow")
    free_text.border_effect.not_nil!.style.should eq("C")
    free_text.rect_difference.not_nil!.width.should eq(3.0_f32)
    free_text.rect_differences.should eq([1.0, 2.0, 4.0, 6.0])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine do
  it "stores line geometry, ending styles, and caption offsets" do
    line = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine.new
    interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.4_f32, 0.5_f32, 0.6_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

    line.line = [1, 2, 3, 4]
    line.start_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_CIRCLE
    line.end_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_SQUARE
    line.interior_color = interior_color
    line.caption = true
    line.leader_line_length = 7
    line.leader_line_extension_length = 8
    line.leader_line_offset_length = 9
    line.caption_positioning = "Top"
    line.caption_horizontal_offset = 1.25
    line.caption_vertical_offset = -2.5

    line.subtype.should eq("Line")
    line.line.should eq([1.0, 2.0, 3.0, 4.0])
    line.start_point_ending_style.should eq("Circle")
    line.end_point_ending_style.should eq("Square")
    line.interior_color.not_nil!.components.should eq([0.4_f32, 0.5_f32, 0.6_f32])
    line.caption?.should be_true
    line.leader_line_length.should eq(7.0)
    line.leader_line_extension_length.should eq(8.0)
    line.leader_line_offset_length.should eq(9.0)
    line.caption_positioning.should eq("Top")
    line.caption_horizontal_offset.should eq(1.25)
    line.caption_vertical_offset.should eq(-2.5)
  end

  it "builds a line appearance stream with caption and line endings" do
    line = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine.new
    border_style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
    line.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 1.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    line.interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    line.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 10.0_f32, 20.0_f32, 10.0_f32)
    line.line = [10, 10, 30, 10]
    line.contents = "Hello"
    line.caption = true
    line.caption_positioning = "Top"
    line.caption_horizontal_offset = 1
    line.caption_vertical_offset = 2
    line.start_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_CIRCLE
    line.end_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_CLOSED_ARROW
    border_style.width = 2
    line.border_style = border_style

    line.construct_appearances

    content = String.new(line.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("0 0 1 RG")
    content.should contain("1 1 0 rg")
    content.should contain("2 w")
    content.should contain("BT")
    content.should contain("Tf")
    content.should contain("(Hello) Tj")
    content.should contain("q")
    content.should contain("Q")
    content.scan(/\bB\b/).size.should be >= 1
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup do
  it "stores popup state and resolves markup parent" do
    popup = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup.new
    parent = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    popup.open = true
    popup.parent = parent

    popup.subtype.should eq("Popup")
    popup.open?.should be_true
    popup.parent.should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationMarkup)
    popup.parent.not_nil!.subtype.should eq("Text")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolygon do
  it "stores polygon color, vertices, path, and border effect" do
    polygon = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolygon.new
    interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.1_f32, 0.3_f32, 0.5_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    border_effect = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary.new
    path = Pdfbox::Cos::Array.new
    path.add(Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(1), Pdfbox::Cos::Integer.new(2)]))
    path.add(Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(3), Pdfbox::Cos::Integer.new(4)]))

    border_effect.intensity = 2
    polygon.interior_color = interior_color
    polygon.border_effect = border_effect
    polygon.vertices = [1, 2, 3, 4, 5, 6]
    polygon.cos_object[Pdfbox::Cos::Name.new("Path")] = path

    polygon.subtype.should eq("Polygon")
    polygon.interior_color.not_nil!.components.should eq([0.1_f32, 0.3_f32, 0.5_f32])
    polygon.border_effect.not_nil!.intensity.should eq(2.0)
    polygon.vertices.should eq([1.0, 2.0, 3.0, 4.0, 5.0, 6.0])
    polygon.path.should eq([[1.0, 2.0], [3.0, 4.0]])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolyline do
  it "stores polyline endings, interior color, and vertices" do
    polyline = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPolyline.new
    interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.2_f32, 0.4_f32, 0.6_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

    polyline.start_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_OPEN_ARROW
    polyline.end_point_ending_style = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLine::LE_CLOSED_ARROW
    polyline.interior_color = interior_color
    polyline.vertices = [1, 2, 3, 4]

    polyline.subtype.should eq("PolyLine")
    polyline.start_point_ending_style.should eq("OpenArrow")
    polyline.end_point_ending_style.should eq("ClosedArrow")
    polyline.interior_color.not_nil!.components.should eq([0.2_f32, 0.4_f32, 0.6_f32])
    polyline.vertices.should eq([1.0, 2.0, 3.0, 4.0])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationInk do
  it "stores ink paths" do
    ink = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationInk.new

    ink.ink_list = [[1, 2, 3, 4], [5, 6]]

    ink.subtype.should eq("Ink")
    ink.ink_list.should eq([[1.0, 2.0, 3.0, 4.0], [5.0, 6.0]])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationRubberStamp do
  it "stores stamp name and defaults to Draft" do
    stamp = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationRubberStamp.new

    stamp.name.should eq("Draft")
    stamp.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationRubberStamp::NAME_APPROVED

    stamp.subtype.should eq("Stamp")
    stamp.name.should eq("Approved")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSound do
  it "stores sound subtype" do
    sound = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSound.new

    sound.subtype.should eq("Sound")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText do
  it "stores text annotation state and defaults the icon name" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.open = true
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_KEY
    text_annotation.state = "Accepted"
    text_annotation.state_model = "Review"

    text_annotation.subtype.should eq("Text")
    text_annotation.open?.should be_true
    text_annotation.name.should eq("Key")
    text_annotation.state.should eq("Accepted")
    text_annotation.state_model.should eq("Review")
  end

  it "defaults the icon name to Note" do
    Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new.name.should eq("Note")
  end

  it "builds the default note appearance stream and normalizes rect flags" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 30.0_f32)

    text_annotation.construct_appearances

    appearance = text_annotation.normal_appearance_stream.not_nil!
    text_annotation.rectangle.not_nil!.width.should eq(18.0_f32)
    text_annotation.rectangle.not_nil!.height.should eq(20.0_f32)
    text_annotation.no_rotate?.should be_true
    text_annotation.no_zoom?.should be_true
    appearance.bbox.not_nil!.width.should eq(18.0_f32)
    appearance.bbox.not_nil!.height.should eq(20.0_f32)

    content = String.new(appearance.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 g")
    content.should contain("4 M")
    content.should contain("1 j")
    content.should contain("0 J")
    content.should contain("0.61 w")
    content.should contain("1 1 16 18 re")
    content.should contain("B")
  end

  it "builds the insert appearance stream" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_INSERT

    text_annotation.construct_appearances

    content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("1 g")
    content.should contain("4 M")
    content.should contain("0 j")
    content.should contain("0 J")
    content.should contain("0.59 w")
    content.should contain("7.5 18 m")
    content.should contain("1 1 l")
    content.should contain("15 1 l")
    content.should contain("b")
  end

  it "builds the circle appearance stream with graphics state and concentric paths" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_CIRCLE

    text_annotation.construct_appearances

    content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("0.95 0 0 0.95 0 0 cm")
    content.should contain("1 0 0 1 0 0.5 cm")
    content.should contain("q")
    content.should contain("/gs1 gs")
    content.should contain("1 g")
    content.should contain("0.59 w")
    content.scan(/\bc\b/).size.should be >= 8
    content.should contain("B")
  end

  it "builds the right-arrow appearance stream with circle backdrop" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_RIGHT_ARROW

    text_annotation.construct_appearances

    content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("/gs1 gs")
    content.should contain("1 g")
    content.should contain("8 17.5 m")
    content.should contain("18 10 l")
    content.should contain("B")
  end

  it "builds the comment appearance stream with scaled outer path" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 18.0_f32, 40.0_f32, 40.0_f32)
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_COMMENT

    text_annotation.construct_appearances

    content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("/gs1 gs")
    content.should contain("0.3 0.3 17.4 17.4 re")
    content.should contain("0.003 0 0 0.003 0 0 cm")
    content.should contain("1 0 0 1 500 -300 cm")
    content.should contain("2549 5269 m")
    content.should contain("b")
  end

  it "builds the up-left-arrow appearance stream with rotation" do
    text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new

    text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 17.0_f32, 40.0_f32, 40.0_f32)
    text_annotation.name = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_UP_LEFT_ARROW

    text_annotation.construct_appearances

    content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
    content.should contain("4 M")
    content.should contain("1 j")
    content.should contain("0 J")
    content.should contain("0.59 w")
    content.should contain("0.70711 0.70711 -0.70711 0.70711 8 -4 cm")
    content.should contain("8.5 19 l")
    content.should contain("b")
  end

  it "builds help and paragraph icon appearances from standard14 glyph paths" do
    {
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_HELP      => "500 375 cm",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_PARAGRAPH => "850 900 cm",
    }.each do |icon_name, marker|
      text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
      text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
      text_annotation.name = icon_name

      text_annotation.construct_appearances

      content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
      content.should contain("/gs1 gs")
      content.should contain(marker)
      content.scan(/\bc\b/).size.should be > 0
    end
  end

  it "builds new-paragraph, cross-hairs, and key appearances" do
    {
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_NEW_PARAGRAPH => "200 0 cm",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_CROSS_HAIRS   => "0 50 cm",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_KEY           => "4799 4004 m",
    }.each do |icon_name, marker|
      text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
      text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
      text_annotation.name = icon_name

      text_annotation.construct_appearances

      content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
      content.should contain(marker)
    end
  end

  it "builds the remaining text icon appearances" do
    {
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_CROSS         => "B",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_CHECK         => "B",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_STAR          => "B",
      Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText::NAME_RIGHT_POINTER => "B",
    }.each do |icon_name, marker|
      text_annotation = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
      text_annotation.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 20.0_f32, 40.0_f32, 40.0_f32)
      text_annotation.name = icon_name

      text_annotation.construct_appearances

      content = String.new(text_annotation.normal_appearance_stream.not_nil!.content_stream.create_input_stream.getb_to_end)
      content.should contain(marker)
      content.scan(/\bc\b|\bl\b/).size.should be > 0
    end
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationTextMarkup do
  it "stores quad points and default empty arrays for text-markup subtypes" do
    highlight = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationHighlight.new
    underline = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationUnderline.new
    strikeout = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationStrikeout.new
    squiggly = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquiggly.new

    highlight.quad_points.should eq([] of Float64)
    highlight.quad_points = [1, 2, 3.5, 4]

    highlight.quad_points.should eq([1.0, 2.0, 3.5, 4.0])
    underline.subtype.should eq("Underline")
    strikeout.subtype.should eq("StrikeOut")
    squiggly.subtype.should eq("Squiggly")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquareCircle do
  it "stores shared square-circle geometry helpers" do
    circle = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new
    square = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
    interior_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.7_f32, 0.2_f32, 0.1_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    border_effect = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary.new
    rect_difference = Pdfbox::Pdmodel::Common::PDRectangle.new(2.0_f32, 3.0_f32, 4.0_f32, 5.0_f32)

    border_effect.style = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
    circle.interior_color = interior_color
    circle.border_effect = border_effect
    circle.rect_differences = [1, 2, 3, 4]
    circle.rect_difference = rect_difference

    circle.subtype.should eq("Circle")
    square.subtype.should eq("Square")
    circle.interior_color.not_nil!.components.should eq([0.7_f32, 0.2_f32, 0.1_f32])
    circle.border_effect.not_nil!.style.should eq("C")
    circle.rect_difference.not_nil!.height.should eq(5.0_f32)
    circle.rect_differences.should eq([2.0, 3.0, 6.0, 8.0])
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::AnnotationFilter do
  it "filters annotations through the accept callback" do
    filter = TestAnnotationFilter.new
    candidate = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new

    filter.accept(candidate).should be_false
    candidate.printed = true
    filter.accept(candidate).should be_true
  end
end
