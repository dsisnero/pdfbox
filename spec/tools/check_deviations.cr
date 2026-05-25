require "../spec_helper"

pdfs = [
  "PDFBOX-3053-reduced.pdf",
  "PDFBOX-3061-092465-reduced.pdf",
  "PDFBOX-3110-poems-beads.pdf",
  "PDFBOX-3110-poems-beads-cropbox.pdf",
  "FC60_Times.pdf",
  "PDFBOX-3127-RAU4G6QMOVRYBISJU7R6MOVZCRFUO7P4-VFont.pdf",
  "PDFBOX-4532-reduced.pdf",
  "cweb.pdf",
]
input_dir = File.expand_path("../../vendor/pdfbox/pdfbox/src/test/resources/input", __DIR__)

pdfs.each do |basename|
  pdf_path = File.join(input_dir, basename)
  expected_path = "#{pdf_path}.txt"
  next unless File.exists?(expected_path)

  doc = Pdfbox::Pdmodel::Document.load(pdf_path)
  begin
    stripper = Pdfbox::Text::PDFTextStripper.new
    stripper.line_separator = "\n"
    actual = stripper.get_text(doc)

    expected = File.read(expected_path)
    expected = expected[1..] if expected.starts_with?("\uFEFF")

    a_norm = actual.gsub(/\r\n?/, "\n").strip
    e_norm = expected.gsub(/\r\n?/, "\n").strip

    if a_norm == e_norm
      puts "#{basename}: MATCH"
    else
      a_lines = a_norm.lines
      e_lines = e_norm.lines
      diffs = 0
      min = a_lines.size < e_lines.size ? a_lines.size : e_lines.size
      min.times { |i| diffs += 1 if a_lines[i] != e_lines[i] }
      diffs += (a_lines.size - e_lines.size).abs
      puts "#{basename}: FAIL (#{diffs} line diffs, crystal=#{a_lines.size}L java=#{e_lines.size}L)"
    end
  rescue ex
    puts "#{basename}: ERROR #{ex.message[0..80]}"
  ensure
    doc.close
  end
end
