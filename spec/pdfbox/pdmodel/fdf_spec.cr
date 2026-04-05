require "../../spec_helper"
require "../../../src/pdfbox"

describe Pdfbox::Pdmodel::Fdf::FDFDocument do
  it "writes catalog version in fdf output" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    document.catalog.version = "1.7"

    document.to_fdf.should contain("/Version /1.7")
  end

  it "writes xfdf through the catalog and dictionary wrappers" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    document.catalog.fdf.file = "sample.pdf"
    field = Pdfbox::Pdmodel::Fdf::FDFField.new("name")
    field.value = "Alice"
    document.catalog.fdf.fields = [field]

    xfdf = document.to_xfdf
    xfdf.should contain(%(<f href="sample.pdf" />))
    xfdf.should contain(%(<field name="name">))
    xfdf.should contain("<value>Alice</value>")
  end

  it "saves to io for fdf and xfdf outputs" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    document.catalog.fdf.file = "sample.pdf"

    fdf_io = IO::Memory.new
    xfdf_io = IO::Memory.new
    document.save(fdf_io)
    document.save_xfdf(xfdf_io)

    fdf_io.to_s.should contain("%FDF-1.2")
    xfdf_io.to_s.should contain("<xfdf ")
  end

  it "supports replacing the catalog and exposes lightweight wrappers" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    catalog = Pdfbox::Pdmodel::Fdf::FDFCatalog.new
    catalog.version = "1.4"
    dictionary = Pdfbox::Pdmodel::Fdf::FDFDictionary.new
    dictionary.file = "other.pdf"
    catalog.fdf = dictionary

    document.set_catalog(catalog)

    document.catalog.should eq(catalog)
    document.catalog.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    document.catalog.fdf.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    document.get_document.should be_nil
    document.close
  end

  it "round-trips status, target, and encoding through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    document.catalog.fdf.status = "Imported"
    document.catalog.fdf.target = "_blank"
    document.catalog.fdf.encoding = "UTF-8"

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/Status (Imported)")
    serialized.should contain("/Target (_blank)")
    serialized.should contain("/Encoding /UTF-8")
    parsed.catalog.fdf.status.should eq("Imported")
    parsed.catalog.fdf.target.should eq("_blank")
    parsed.catalog.fdf.encoding.should eq("UTF-8")
  end

  it "round-trips pages with page info through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    page = Pdfbox::Pdmodel::Fdf::FDFPage.new
    page_info = Pdfbox::Pdmodel::Fdf::FDFPageInfo.new
    page_info.cos_object[Pdfbox::Cos::Name.new("Label")] = Pdfbox::Cos::String.new("Cover")
    page.page_info = page_info
    document.catalog.fdf.pages = [page]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/Pages [")
    serialized.should contain("/Info <<")
    parsed.catalog.fdf.pages.not_nil!.size.should eq(1)
    parsed.catalog.fdf.pages.not_nil!.first.page_info.not_nil!.cos_object[Pdfbox::Cos::Name.new("Label")].as(Pdfbox::Cos::String).value.should eq("Cover")
  end

  it "round-trips page templates with named references, fields, and rename through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "template.pdf"

    page_reference = Pdfbox::Pdmodel::Fdf::FDFNamedPageReference.new
    page_reference.name = "TemplatePage"
    page_reference.file_specification = file_spec

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("templateField")
    field.value = "FromTemplate"

    template = Pdfbox::Pdmodel::Fdf::FDFTemplate.new
    template.template_reference = page_reference
    template.fields = [field]
    template.rename = true

    page = Pdfbox::Pdmodel::Fdf::FDFPage.new
    page.templates = [template]
    document.catalog.fdf.pages = [page]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/Templates [")
    serialized.should contain("/TRef <<")
    serialized.should contain("/Name (TemplatePage)")
    serialized.should contain("/F (template.pdf)")
    serialized.should contain("/Rename true")

    parsed_page = parsed.catalog.fdf.pages.not_nil!.first
    parsed_template = parsed_page.templates.not_nil!.first
    parsed_template.should_rename?.should be_true
    parsed_template.template_reference.not_nil!.name.should eq("TemplatePage")
    parsed_template.template_reference.not_nil!.file_specification.not_nil!.file.should eq("template.pdf")
    parsed_template.fields.not_nil!.first.partial_field_name.should eq("templateField")
    parsed_template.fields.not_nil!.first.value.should eq("FromTemplate")
  end

  it "round-trips javascript before, after, and doc actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    javascript = Pdfbox::Pdmodel::Fdf::FDFJavaScript.new
    javascript.before = "app.alert('before')"
    javascript.after = "app.alert('after')"
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    action.action = "app.alert('doc')"
    javascript.doc = {"Open" => action}
    document.catalog.fdf.javascript = javascript

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/JavaScript <<")
    parsed.catalog.fdf.javascript.not_nil!.before.should eq("app.alert('before')")
    parsed.catalog.fdf.javascript.not_nil!.after.should eq("app.alert('after')")
    parsed.catalog.fdf.javascript.not_nil!.doc.not_nil!["Open"].action.should eq("app.alert('doc')")
  end

  it "round-trips field options with strings and option elements through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    option_element = Pdfbox::Pdmodel::Fdf::FDFOptionElement.new
    option_element.option = "ExportValue"
    option_element.default_appearance_string = "/Helv 10 Tf 0 g"

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("choice")
    field.options = ["PlainOption", option_element]
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/Opt [")
    serialized.should contain("(PlainOption)")
    serialized.should contain("[(ExportValue) (/Helv 10 Tf 0 g)]")

    parsed_options = parsed.catalog.fdf.fields.not_nil!.first.options.not_nil!
    parsed_options.first.should eq("PlainOption")
    parsed_option_element = parsed_options.last.as(Pdfbox::Pdmodel::Fdf::FDFOptionElement)
    parsed_option_element.option.should eq("ExportValue")
    parsed_option_element.default_appearance_string.should eq("/Helv 10 Tf 0 g")
  end

  it "round-trips appearance stream references and icon fit through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    appearance_reference = Pdfbox::Pdmodel::Fdf::FDFNamedPageReference.new
    appearance_reference.name = "ButtonFace"

    icon_fit = Pdfbox::Pdmodel::Fdf::FDFIconFit.new
    icon_fit.scale_option = Pdfbox::Pdmodel::Fdf::FDFIconFit::SCALE_OPTION_ONLY_WHEN_ICON_IS_SMALLER
    icon_fit.scale_type = Pdfbox::Pdmodel::Fdf::FDFIconFit::SCALE_TYPE_ANAMORPHIC
    icon_fit.scale_to_fit_annotation = true
    fractional_space = icon_fit.fractional_space_to_allocate
    fractional_space.min = 0.25
    fractional_space.max = 0.75

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("push")
    field.appearance_stream_reference = appearance_reference
    field.icon_fit = icon_fit
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/APRef <<")
    serialized.should contain("/Name (ButtonFace)")
    serialized.should contain("/IF <<")
    serialized.should contain("/SW /S")
    serialized.should contain("/S /A")
    serialized.should contain("/FB true")

    parsed_field = parsed.catalog.fdf.fields.not_nil!.first
    parsed_field.appearance_stream_reference.not_nil!.name.should eq("ButtonFace")
    parsed_icon_fit = parsed_field.icon_fit.not_nil!
    parsed_icon_fit.scale_option.should eq(Pdfbox::Pdmodel::Fdf::FDFIconFit::SCALE_OPTION_ONLY_WHEN_ICON_IS_SMALLER)
    parsed_icon_fit.scale_type.should eq(Pdfbox::Pdmodel::Fdf::FDFIconFit::SCALE_TYPE_ANAMORPHIC)
    parsed_icon_fit.should_scale_to_fit_annotation?.should be_true
    parsed_icon_fit.fractional_space_to_allocate.min.should eq(0.25)
    parsed_icon_fit.fractional_space_to_allocate.max.should eq(0.75)
  end

  it "round-trips field actions and additional actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    action.action = "app.alert('primary')"

    focus_action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    focus_action.action = "app.alert('focus')"
    additional_actions = Pdfbox::Pdmodel::Interactive::Action::PDAdditionalActions.new
    additional_actions.f = focus_action

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("interactive")
    field.action = action
    field.additional_actions = additional_actions
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/A <<")
    serialized.should contain("/S /JavaScript")
    serialized.should contain("/AA <<")
    serialized.should contain("/F <<")

    parsed_field = parsed.catalog.fdf.fields.not_nil!.first
    parsed_field.action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    parsed_field.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('primary')")
    parsed_field.additional_actions.not_nil!.f.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    parsed_field.additional_actions.not_nil!.f.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('focus')")
  end

  it "routes uri and named actions through the lightweight action factory" do
    uri_action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    uri_action.uri = "https://example.com"
    uri_action.track_mouse_position = true

    named_action = Pdfbox::Pdmodel::Interactive::Action::PDActionNamed.new
    named_action.n = "NextPage"

    uri_from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(uri_action.cos_object)
    named_from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(named_action.cos_object)

    uri_from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    uri_from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com")
    uri_from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).track_mouse_position?.should be_true
    named_from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed)
    named_from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed).n.should eq("NextPage")
  end

  it "round-trips uri field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    action.uri = "https://example.com/form"
    action.track_mouse_position = true

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("link")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/A <<")
    serialized.should contain("/S /URI")
    serialized.should contain("/URI (https://example.com/form)")
    serialized.should contain("/IsMap true")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/form")
    parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).track_mouse_position?.should be_true
  end

  it "routes launch actions through the lightweight action factory" do
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch.new
    action.f = "viewer.exe"
    action.d = "C:\\PDF"
    action.o = "open"
    action.p = "/silent"
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch)
    parsed = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch)
    parsed.f.should eq("viewer.exe")
    parsed.d.should eq("C:\\PDF")
    parsed.o.should eq("open")
    parsed.p.should eq("/silent")
    parsed.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow)
  end

  it "round-trips launch field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "launch-target.pdf"

    win = Pdfbox::Pdmodel::Interactive::Action::PDWindowsLaunchParams.new
    win.filename = "AcroRd32.exe"
    win.directory = "C:\\Program Files\\Adobe"
    win.operation = Pdfbox::Pdmodel::Interactive::Action::PDWindowsLaunchParams::OPERATION_PRINT
    win.execute_param = "/h"

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch.new
    action.file = file_spec
    action.d = "C:\\Docs"
    action.o = "print"
    action.p = "/p"
    action.win_launch_params = win
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("launch")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /Launch")
    serialized.should contain("/F (launch-target.pdf)")
    serialized.should contain("/D (C:\\\\Docs)")
    serialized.should contain("/O (print)")
    serialized.should contain("/P (/p)")
    serialized.should contain("/NewWindow false")
    serialized.should contain("/Win <<")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch)
    launch = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch)
    launch.file.not_nil!.file.should eq("launch-target.pdf")
    launch.d.should eq("C:\\Docs")
    launch.o.should eq("print")
    launch.p.should eq("/p")
    launch.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow)
    launch.win_launch_params.not_nil!.filename.should eq("AcroRd32.exe")
    launch.win_launch_params.not_nil!.directory.should eq("C:\\Program Files\\Adobe")
    launch.win_launch_params.not_nil!.operation.should eq(Pdfbox::Pdmodel::Interactive::Action::PDWindowsLaunchParams::OPERATION_PRINT)
    launch.win_launch_params.not_nil!.execute_param.should eq("/h")
  end

  it "routes import-data actions through the lightweight action factory" do
    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "import-data.fdf"

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionImportData.new
    action.file = file_spec

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionImportData)
    from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionImportData).file.not_nil!.file.should eq("import-data.fdf")
  end

  it "routes hide actions through the lightweight action factory" do
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionHide.new
    action.t = Pdfbox::Cos::String.new("WidgetName")
    action.h = false

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionHide)
    hide = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionHide)
    hide.t.should be_a(Pdfbox::Cos::String)
    hide.t.as(Pdfbox::Cos::String).value.should eq("WidgetName")
    hide.h.should be_false
  end

  it "routes embedded goto actions through the lightweight action factory" do
    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "embedded.pdf"

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination.new
    destination.page_number = 3
    destination.left = 72

    target = Pdfbox::Pdmodel::Interactive::Action::PDTargetDirectory.new
    target.relationship = Pdfbox::Cos::Name.new("C")
    target.filename = "attachment.pdf"
    target.page_number = 2
    target.annotation_index = 1

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo.new
    action.file = file_spec
    action.destination = destination
    action.target_directory = target
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo)
    embedded = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo)
    embedded.file.not_nil!.file.should eq("embedded.pdf")
    embedded.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow)
    embedded.destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination)
    embedded.destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination).page_number.should eq(3)
    embedded.target_directory.not_nil!.relationship.not_nil!.value.should eq("C")
    embedded.target_directory.not_nil!.filename.should eq("attachment.pdf")
    embedded.target_directory.not_nil!.page_number.should eq(2)
    embedded.target_directory.not_nil!.annotation_index.should eq(1)
  end

  it "routes submit-form actions through the lightweight action factory" do
    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "submit-endpoint"

    fields = Pdfbox::Cos::Array.new
    fields.add(Pdfbox::Cos::String.new("FieldOne"))
    fields.add(Pdfbox::Cos::String.new("FieldTwo"))

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm.new
    action.file = file_spec
    action.fields = fields
    action.flags = 5

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm)
    submit = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm)
    submit.file.not_nil!.file.should eq("submit-endpoint")
    submit.fields.not_nil!.size.should eq(2)
    submit.fields.not_nil![0].as(Pdfbox::Cos::String).value.should eq("FieldOne")
    submit.fields.not_nil![1].as(Pdfbox::Cos::String).value.should eq("FieldTwo")
    submit.flags.should eq(5)
  end

  it "routes goto actions through the lightweight action factory" do
    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new("Chapter1")
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo.new
    action.destination = destination

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
    parsed_destination = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo).destination
    parsed_destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination)
    parsed_destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination).named_destination.should eq("Chapter1")
  end

  it "routes remote goto actions through the lightweight action factory" do
    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "remote.pdf"

    destination = Pdfbox::Cos::Array.new
    destination.add(Pdfbox::Cos::Integer.new(2))
    destination.add(Pdfbox::Cos::Name.new("FitH"))
    destination.add(Pdfbox::Cos::Integer.new(144))

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo.new
    action.file = file_spec
    action.d = destination
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow

    from_factory = Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(action.cos_object)

    from_factory.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo)
    parsed = from_factory.as(Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo)
    parsed.file.not_nil!.file.should eq("remote.pdf")
    parsed.d.should be_a(Pdfbox::Cos::Array)
    parsed_destination = parsed.d.as(Pdfbox::Cos::Array)
    parsed_destination[0].as(Pdfbox::Cos::Integer).value.should eq(2_i64)
    parsed_destination.get_name(1).should eq("FitH")
    parsed_destination[2].as(Pdfbox::Cos::Integer).value.should eq(144_i64)
    parsed.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::NewWindow)
  end

  it "round-trips goto field actions with page xyz destinations through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination.new
    destination.page = Pdfbox::Cos::Dictionary.new({
      Pdfbox::Cos::Name.new("Type") => Pdfbox::Cos::Name.new("Page").as(Pdfbox::Cos::Base),
    })
    destination.left = 12
    destination.top = 34
    destination.zoom = 1.5

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo.new
    action.destination = destination

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("goto")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /GoTo")
    serialized.should contain("/D [")
    serialized.should contain("/XYZ")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
    parsed_destination = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo).destination
    parsed_destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination)
    xyz = parsed_destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageXYZDestination)
    xyz.left.should eq(12)
    xyz.top.should eq(34)
    xyz.zoom.should eq(1.5)
  end

  it "creates fit destinations through the lightweight destination factory" do
    fit = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination.new
    fit.fit_bounding_box = true

    fit_height = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination.new
    fit_height.left = 22
    fit_height.fit_bounding_box = true

    fit_width = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination.new
    fit_width.top = 33
    fit_width.fit_bounding_box = true

    fit_rectangle = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination.new
    fit_rectangle.left = 1
    fit_rectangle.bottom = 2
    fit_rectangle.right = 3
    fit_rectangle.top = 4

    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit.cos_object).should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination)
    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_height.cos_object).should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination)
    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_width.cos_object).should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination)
    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_rectangle.cos_object).should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination)

    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_height.cos_object).as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitHeightDestination).left.should eq(22)
    Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_width.cos_object).as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination).top.should eq(33)
    parsed_rect = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(fit_rectangle.cos_object).as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination)
    parsed_rect.left.should eq(1)
    parsed_rect.bottom.should eq(2)
    parsed_rect.right.should eq(3)
    parsed_rect.top.should eq(4)
  end

  it "round-trips goto field actions with fit width destinations through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination.new
    destination.page = Pdfbox::Cos::Dictionary.new({
      Pdfbox::Cos::Name.new("Type") => Pdfbox::Cos::Name.new("Page").as(Pdfbox::Cos::Base),
    })
    destination.top = 44
    destination.fit_bounding_box = true

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo.new
    action.destination = destination

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("fitWidth")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/FitBH")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
    parsed_destination = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo).destination
    parsed_destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination)
    fit_width = parsed_destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitWidthDestination)
    fit_width.top.should eq(44)
    fit_width.fit_bounding_box?.should be_true
  end

  it "round-trips remote goto field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "remote-target.pdf"

    destination = Pdfbox::Cos::Array.new
    destination.add(Pdfbox::Cos::Integer.new(5))
    destination.add(Pdfbox::Cos::Name.new("FitR"))
    destination.add(Pdfbox::Cos::Integer.new(10))
    destination.add(Pdfbox::Cos::Integer.new(20))
    destination.add(Pdfbox::Cos::Integer.new(30))
    destination.add(Pdfbox::Cos::Integer.new(40))

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo.new
    action.file = file_spec
    action.d = destination
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("remoteGoto")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /GoToR")
    serialized.should contain("/F (remote-target.pdf)")
    serialized.should contain("/D [5 /FitR 10 20 30 40]")
    serialized.should contain("/NewWindow false")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo)
    remote_goto = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionRemoteGoTo)
    remote_goto.file.not_nil!.file.should eq("remote-target.pdf")
    remote_goto.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow)
    remote_destination = remote_goto.d
    remote_destination.should be_a(Pdfbox::Cos::Array)
    destination_array = remote_destination.as(Pdfbox::Cos::Array)
    destination_array[0].as(Pdfbox::Cos::Integer).value.should eq(5_i64)
    destination_array.get_name(1).should eq("FitR")
    destination_array[2].as(Pdfbox::Cos::Integer).value.should eq(10_i64)
    destination_array[3].as(Pdfbox::Cos::Integer).value.should eq(20_i64)
    destination_array[4].as(Pdfbox::Cos::Integer).value.should eq(30_i64)
    destination_array[5].as(Pdfbox::Cos::Integer).value.should eq(40_i64)
  end

  it "round-trips import-data field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "import-form.fdf"

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionImportData.new
    action.file = file_spec

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("importData")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /ImportData")
    serialized.should contain("/F (import-form.fdf)")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionImportData)
    parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionImportData).file.not_nil!.file.should eq("import-form.fdf")
  end

  it "round-trips hide field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    targets = Pdfbox::Cos::Array.new
    targets.add(Pdfbox::Cos::String.new("FieldA"))
    targets.add(Pdfbox::Cos::String.new("FieldB"))

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionHide.new
    action.t = targets
    action.h = false

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("hideAction")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /Hide")
    serialized.should contain("/T [(FieldA) (FieldB)]")
    serialized.should contain("/H false")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionHide)
    hide = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionHide)
    hide.h.should be_false
    parsed_targets = hide.t
    parsed_targets.should be_a(Pdfbox::Cos::Array)
    parsed_targets.as(Pdfbox::Cos::Array)[0].as(Pdfbox::Cos::String).value.should eq("FieldA")
    parsed_targets.as(Pdfbox::Cos::Array)[1].as(Pdfbox::Cos::String).value.should eq("FieldB")
  end

  it "round-trips embedded goto field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "embedded-target.pdf"

    destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination.new
    destination.page_number = 4
    destination.left = 10
    destination.bottom = 20
    destination.right = 30
    destination.top = 40

    nested_target = Pdfbox::Pdmodel::Interactive::Action::PDTargetDirectory.new
    nested_target.relationship = Pdfbox::Cos::Name.new("P")
    nested_target.named_destination = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination.new("NestedDest")
    nested_target.annotation_name = "AnnotName"

    target = Pdfbox::Pdmodel::Interactive::Action::PDTargetDirectory.new
    target.relationship = Pdfbox::Cos::Name.new("C")
    target.filename = "child.pdf"
    target.page_number = 7
    target.annotation_index = 5
    target.target_directory = nested_target

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo.new
    action.file = file_spec
    action.destination = destination
    action.target_directory = target
    action.open_in_new_window = Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("embeddedGoto")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /GoToE")
    serialized.should contain("/F (embedded-target.pdf)")
    serialized.should contain("/D [4 /FitR 10 20 30 40]")
    serialized.should contain("/T <<")
    serialized.should contain("/R /C")
    serialized.should contain("/N (child.pdf)")
    serialized.should contain("/P 7")
    serialized.should contain("/A 5")
    serialized.should contain("/NewWindow false")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo)
    embedded = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionEmbeddedGoTo)
    embedded.file.not_nil!.file.should eq("embedded-target.pdf")
    embedded.open_in_new_window.should eq(Pdfbox::Pdmodel::Interactive::Action::OpenMode::SameWindow)
    embedded.destination.should be_a(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination)
    fit_rect = embedded.destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitRectangleDestination)
    fit_rect.page_number.should eq(4)
    fit_rect.left.should eq(10)
    fit_rect.bottom.should eq(20)
    fit_rect.right.should eq(30)
    fit_rect.top.should eq(40)

    parsed_target = embedded.target_directory.not_nil!
    parsed_target.relationship.not_nil!.value.should eq("C")
    parsed_target.filename.should eq("child.pdf")
    parsed_target.page_number.should eq(7)
    parsed_target.annotation_index.should eq(5)
    parsed_nested = parsed_target.target_directory.not_nil!
    parsed_nested.relationship.not_nil!.value.should eq("P")
    parsed_nested.named_destination.not_nil!.named_destination.should eq("NestedDest")
    parsed_nested.annotation_name.should eq("AnnotName")
  end

  it "round-trips submit-form field actions through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    file_spec = Pdfbox::Pdmodel::Common::Filespecification::PDSimpleFileSpecification.new
    file_spec.file = "https://example.com/submit"

    fields = Pdfbox::Cos::Array.new
    fields.add(Pdfbox::Cos::String.new("FieldOne"))
    fields.add(Pdfbox::Cos::String.new("FieldTwo"))

    action = Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm.new
    action.file = file_spec
    action.fields = fields
    action.flags = 17

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("submitForm")
    field.action = action
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/S /SubmitForm")
    serialized.should contain("/F (https://example.com/submit)")
    serialized.should contain("/Fields [(FieldOne) (FieldTwo)]")
    serialized.should contain("/Flags 17")

    parsed_action = parsed.catalog.fdf.fields.not_nil!.first.action
    parsed_action.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm)
    submit = parsed_action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm)
    submit.file.not_nil!.file.should eq("https://example.com/submit")
    submit.flags.should eq(17)
    submit.fields.not_nil!.size.should eq(2)
    submit.fields.not_nil![0].as(Pdfbox::Cos::String).value.should eq("FieldOne")
    submit.fields.not_nil![1].as(Pdfbox::Cos::String).value.should eq("FieldTwo")
  end

  it "round-trips field appearance dictionaries through fdf serialization" do
    document = Pdfbox::Pdmodel::Fdf::FDFDocument.new

    normal_stream = Pdfbox::Cos::Dictionary.new
    normal_stream[Pdfbox::Cos::Name.new("State")] = Pdfbox::Cos::String.new("normal")
    rollover_stream = Pdfbox::Cos::Dictionary.new
    rollover_stream[Pdfbox::Cos::Name.new("State")] = Pdfbox::Cos::String.new("rollover")
    down_stream = Pdfbox::Cos::Dictionary.new
    down_stream[Pdfbox::Cos::Name.new("State")] = Pdfbox::Cos::String.new("down")

    normal_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(
      Pdfbox::Cos::Dictionary.new({
        Pdfbox::Cos::Name.new("default") => normal_stream.as(Pdfbox::Cos::Base),
      })
    )
    rollover_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(
      Pdfbox::Cos::Dictionary.new({
        Pdfbox::Cos::Name.new("hover") => rollover_stream.as(Pdfbox::Cos::Base),
      })
    )
    down_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(
      Pdfbox::Cos::Dictionary.new({
        Pdfbox::Cos::Name.new("pressed") => down_stream.as(Pdfbox::Cos::Base),
      })
    )

    appearance_dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
    appearance_dictionary.normal_appearance = normal_entry
    appearance_dictionary.rollover_appearance = rollover_entry
    appearance_dictionary.down_appearance = down_entry

    field = Pdfbox::Pdmodel::Fdf::FDFField.new("appearance")
    field.appearance_dictionary = appearance_dictionary
    document.catalog.fdf.fields = [field]

    serialized = document.to_fdf
    parsed = Pdfbox::Pdmodel::Fdf::FDFDocument.from_fdf(serialized)

    serialized.should contain("/AP <<")
    serialized.should contain("/N <<")
    serialized.should contain("/R <<")
    serialized.should contain("/D <<")

    parsed_appearance = parsed.catalog.fdf.fields.not_nil!.first.appearance_dictionary.not_nil!
    parsed_appearance.normal_appearance.not_nil!.sub_dictionary[Pdfbox::Cos::Name.new("default")].cos_object[Pdfbox::Cos::Name.new("State")].as(Pdfbox::Cos::String).value.should eq("normal")
    parsed_appearance.rollover_appearance.not_nil!.sub_dictionary[Pdfbox::Cos::Name.new("hover")].cos_object[Pdfbox::Cos::Name.new("State")].as(Pdfbox::Cos::String).value.should eq("rollover")
    parsed_appearance.down_appearance.not_nil!.sub_dictionary[Pdfbox::Cos::Name.new("pressed")].cos_object[Pdfbox::Cos::Name.new("State")].as(Pdfbox::Cos::String).value.should eq("down")
  end

  it "falls back to normal appearance for rollover and down entries" do
    normal_stream = Pdfbox::Cos::Dictionary.new
    normal_stream[Pdfbox::Cos::Name.new("State")] = Pdfbox::Cos::String.new("normal")
    normal_entry = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceEntry.new(
      Pdfbox::Cos::Dictionary.new({
        Pdfbox::Cos::Name.new("default") => normal_stream.as(Pdfbox::Cos::Base),
      })
    )

    appearance_dictionary = Pdfbox::Pdmodel::Interactive::Annotation::PDAppearanceDictionary.new
    appearance_dictionary.normal_appearance = normal_entry

    appearance_dictionary.rollover_appearance.not_nil!.cos_object.should eq(normal_entry.cos_object)
    appearance_dictionary.down_appearance.not_nil!.cos_object.should eq(normal_entry.cos_object)
  end
end
