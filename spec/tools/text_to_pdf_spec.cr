require "../spec_helper"

# Source of truth: vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/TextToPDF.java
describe Tools::TextToPDF do
  it "converts a text file to PDF" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      File.write(text_file, "Hello World\nThis is a test.\n")

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file])

      exit_code.should eq(0)
      File.exists?(pdf_file).should be_true

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  it "creates multi-page PDF for long text" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      lines = Array.new(150) { |i| "Line #{i + 1}: This is a very long line of text that will definitely wrap across multiple lines on the page because it contains many many characters that exceed the available width." }
      File.write(text_file, lines.join("\n"))

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      doc.number_of_pages.should be >= 2
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  it "handles empty text file" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      File.write(text_file, "")

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  it "respects -pageSize option" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      File.write(text_file, "Test content")

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file, "-pageSize", "A4"])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      page = doc.pages[0]
      media_box = page.media_box
      media_box.should_not be_nil
      media_box.not_nil!.width.should eq(595.0)
      media_box.not_nil!.height.should eq(842.0)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  it "respects --landscape option" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      File.write(text_file, "Test content")

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file, "--landscape"])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      page = doc.pages[0]
      media_box = page.media_box
      media_box.should_not be_nil
      media_box.not_nil!.width.should eq(792.0)
      media_box.not_nil!.height.should eq(612.0)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  it "reports error for missing -i" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    tool = Tools::TextToPDF.new(stdout, stderr)
    exit_code = tool.call(["-o", "out.pdf"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Missing required option: -i")
  end

  it "reports error for missing -o" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    begin
      File.write(text_file, "test")
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file])
      exit_code.should eq(1)
      stderr.to_s.should contain("Missing required option: -o")
    ensure
      File.delete(text_file) if File.exists?(text_file)
    end
  end

  it "reports error for nonexistent input file" do
    stdout = IO::Memory.new
    stderr = IO::Memory.new
    tool = Tools::TextToPDF.new(stdout, stderr)
    exit_code = tool.call(["-i", "/nonexistent/file.txt", "-o", "out.pdf"])
    exit_code.should eq(1)
    stderr.to_s.should contain("Input file does not exist")
  end

  # Source of truth: vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools/TestTextToPdf.java:testCreateEmptyPdf
  it "testCreateEmptyPdf: creates single page from empty string" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      File.write(text_file, "")

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file])

      exit_code.should eq(0)
      File.exists?(pdf_file).should be_true

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      doc.number_of_pages.should eq(1)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end

  # Source of truth: vendor/pdfbox/tools/src/test/java/org/apache/pdfbox/tools/TestTextToPdf.java:testOverflow
  it "testOverflow: creates multi-page PDF with word wrap on A6 page" do
    text_file = File.tempname("pdfbox_texttopdf_test_", ".txt")
    pdf_file = File.tempname("pdfbox_texttopdf_test_", ".pdf")
    begin
      lorem_text = "Lorem ipsum dolor sit amet, consetetur sadipscing " \
                   "elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam " \
                   "erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. " \
                   "Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. " \
                   "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod " \
                   "tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. " \
                   "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd " \
                   "gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem " \
                   "ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod " \
                   "tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. " \
                   "At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd " \
                   "gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.\n" \
                   "\n" \
                   "Duis autem vel eum iriure dolor in hendrerit in vulputate velit esse molestie " \
                   "consequat, vel illum dolore eu feugiat nulla facilisis at vero eros et accumsan " \
                   "et iusto odio dignissim qui blandit praesent luptatum zzril delenit augue " \
                   "duis dolore te feugait nulla facilisi. Lorem ipsum dolor sit amet, " \
                   "consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut " \
                   "laoreet dolore magna aliquam erat volutpat.\n" \
                   "\n" \
                   "Ut wisi enim ad minim veniam, quis nostrud exerci tation ullamcorper " \
                   "suscipit lobortis nisl ut aliquip ex ea commodo consequat. " \
                   "Duis autem vel eum iriure dolor in hendrerit in vulputate " \
                   "velit esse molestie consequat, vel illum dolore eu feugiat nulla " \
                   "facilisis at vero eros et accumsan et iusto odio dignissim qui blandit " \
                   "praesent luptatum zzril delenit augue duis dolore te feugait nulla facilisi.\n" \
                   "\n" \
                   "Nam liber tempor cum soluta nobis eleifend option congue nihil imperdiet doming " \
                   "id quod mazim placerat facer."
      File.write(text_file, lorem_text)

      stdout = IO::Memory.new
      stderr = IO::Memory.new
      tool = Tools::TextToPDF.new(stdout, stderr)
      exit_code = tool.call(["-i", text_file, "-o", pdf_file, "-pageSize", "A6"])

      exit_code.should eq(0)

      doc = Pdfbox::Pdmodel::Document.load(pdf_file)
      doc.number_of_pages.should eq(2)
      doc.close
    ensure
      File.delete(text_file) if File.exists?(text_file)
      File.delete(pdf_file) if File.exists?(pdf_file)
    end
  end
end
