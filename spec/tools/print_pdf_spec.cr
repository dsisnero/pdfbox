require "../spec_helper"
require "../../src/tools"

private class FakePrintBackend < Tools::PrintPDF::Backend
  getter last_submission : Submission?
  getter last_infile : String?
  property printers = [] of String
  property default_printer : String? = nil
  property trays = [] of String
  property media_sizes = [] of String
  property exit_code = 0
  property unsupported = ["orientation", "border", "dpi", "noCenter", "noColorOpt", "silentPrint"] of String

  def available_printers : Array(String)
    printers
  end

  def default_printer_name : String?
    default_printer
  end

  def available_trays(printer : String?) : Array(String)
    _ = printer
    trays
  end

  def available_media_sizes(printer : String?) : Array(String)
    _ = printer
    media_sizes
  end

  def submit(infile : String, submission : Submission, stdout_io : IO, stderr_io : IO) : Int32
    _ = stdout_io
    _ = stderr_io
    @last_infile = infile
    @last_submission = submission
    exit_code
  end

  def unimplemented_options : Array(String)
    unsupported
  end
end

private class FakePrintableDocument < Pdfbox::Pdmodel::Document
  property can_print = true

  def current_access_permission : Pdfbox::Pdmodel::Encryption::AccessPermission
    permission = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    permission.can_print = can_print
    permission
  end
end

private class FakePrintPDF < Tools::PrintPDF
  property document = FakePrintableDocument.new

  def initialize(@fake_backend : FakePrintBackend, stdout_io : IO = IO::Memory.new, stderr_io : IO = IO::Memory.new)
    super(stdout_io, stderr_io, @fake_backend)
  end

  protected def load_printable_document(_infile : String, _password : String) : Pdfbox::Pdmodel::Document
    document
  end
end

describe Tools::PrintPDF do
  it "submits printer, duplex, tray, and media size through the backend" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    backend.printers = ["Office"] of String
    backend.trays = ["Tray2"] of String
    backend.media_sizes = ["A4"] of String
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)

    code = tool.call(["-i", "input.pdf", "-printerName", "Office", "-duplex", "duplex", "-tray", "Tray2", "-mediaSize", "A4"])

    code.should eq(0)
    backend.last_infile.should eq("input.pdf")
    backend.last_submission.not_nil!.printer.should eq("Office")
    backend.last_submission.not_nil!.duplex.should eq("sides=two-sided-long-edge")
    backend.last_submission.not_nil!.tray.should eq("Tray2")
    backend.last_submission.not_nil!.media_size.should eq("A4")
  end

  it "uses the document viewer preferences when duplex=document" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)

    viewer_prefs = Pdfbox::Pdmodel::Interactive::PDViewerPreferences.new
    viewer_prefs.duplex = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::DuplexFlipShortEdge
    tool.document.document_catalog.not_nil!.viewer_preferences = viewer_prefs

    code = tool.call(["-i", "input.pdf"])

    code.should eq(0)
    backend.last_submission.not_nil!.duplex.should eq("sides=two-sided-short-edge")
  end

  it "warns and falls back to the default printer when the requested printer is missing" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    backend.printers = ["Lobby"] of String
    backend.default_printer = "Lobby"
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)

    code = tool.call(["-i", "input.pdf", "-printerName", "Unknown"])

    code.should eq(0)
    backend.last_submission.not_nil!.printer.should be_nil
    stderr_io.to_s.should contain("printer 'Unknown' not found, using default 'Lobby'")
    stderr_io.to_s.should contain("Available printer names:")
    stderr_io.to_s.should contain("Lobby")
  end

  it "warns and ignores unsupported tray and media values" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    backend.trays = ["Tray1"] of String
    backend.media_sizes = ["Letter"] of String
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)

    code = tool.call(["-i", "input.pdf", "-tray", "Tray9", "-mediaSize", "A4"])

    code.should eq(0)
    backend.last_submission.not_nil!.tray.should be_nil
    backend.last_submission.not_nil!.media_size.should be_nil
    stderr_io.to_s.should contain("Tray 'Tray9' not supported, ignored.")
    stderr_io.to_s.should contain("media size 'A4' not supported, ignored.")
  end

  it "returns the Java-shaped print permission error" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)
    tool.document.can_print = false

    code = tool.call(["-i", "input.pdf"])

    code.should eq(4)
    stderr_io.to_s.should contain("Error printing document [Error]: You do not have permission to print")
  end

  it "warns when unsupported Java print options are requested" do
    stdout_io = IO::Memory.new
    stderr_io = IO::Memory.new
    backend = FakePrintBackend.new
    tool = FakePrintPDF.new(backend, stdout_io, stderr_io)

    code = tool.call(["-i", "input.pdf", "-orientation", "landscape", "-border", "-dpi", "300", "-noCenter", "-noColorOpt", "-silentPrint"])

    code.should eq(0)
    stderr_io.to_s.should contain("Warning: partial print parity")
    stderr_io.to_s.should contain("orientation=landscape")
    stderr_io.to_s.should contain("dpi=300")
    stderr_io.to_s.should contain("noCenter")
    stderr_io.to_s.should contain("noColorOpt")
    stderr_io.to_s.should contain("silentPrint")
  end
end
