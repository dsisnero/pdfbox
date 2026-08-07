# Deviation checker for known text extraction differences from Java fixtures.
# Run with: crystal run spec/tools/check_deviations.cr
# Status as of 2026-05-25:
#   MATCH: 1 (PDFBOX-3127 rotation — FIXED)
#   FAIL:  7 (root causes documented in plans/parity.md)

require "../spec_helper"

pdfs = [
  "PDFBOX-3053-reduced.pdf",                                # spacing — extra space in "Symp toms"
  "PDFBOX-3061-092465-reduced.pdf",                         # spacing — missing spaces
  "PDFBOX-3110-poems-beads.pdf",                            # beads — column ordering
  "PDFBOX-3110-poems-beads-cropbox.pdf",                    # beads — column ordering
  "FC60_Times.pdf",                                         # encoding — Arabic diacritic ordering
  "PDFBOX-3127-RAU4G6QMOVRYBISJU7R6MOVZCRFUO7P4-VFont.pdf", # rotation — MATCH (fixed)
  "PDFBOX-4532-reduced.pdf",                                # encoding — ToUnicode CMap period→space
  "cweb.pdf",                                               # multiple — spacing + encoding
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

      # Show first few diffs
      diff_shown = 0
      max_lines = Math.max(a_lines.size, e_lines.size)
      max_lines.times do |i|
        a_line = a_lines[i]?
        e_line = e_lines[i]?
        if a_line != e_line && diff_shown < 3
          puts "  Line #{i + 1}:"
          puts "    CRYSTAL: #{a_line.inspect}" if a_line
          puts "    JAVA:    #{e_line.inspect}" if e_line
          diff_shown += 1
        end
      end
    end
  rescue ex
    msg = ex.message || "No message"
    puts "#{basename}: ERROR #{msg[0..80]}"
  ensure
    doc.close
  end
end
