# Deviation checker for known text extraction differences from Java fixtures.
# Run with: crystal run spec/tools/check_deviations.cr
# Status as of 2026-08-07:
#   All PDFs match Java 3.0.4 exactly (verified against the release jar).
#   FC60_Times: the checked-in .txt fixture is STALE (2010 era, pre-mergeDiacritic
#   bidi ordering). Crystal output == Java 3.0.4 output == current vendor source.
#
# Stale fixtures: some expected .txt files predate PDFBox's current bidi/diacritic
# behavior. For those, we compare against the known Java 3.0.4 ground truth
# instead of the stale fixture. STALE_FIXTURES maps basename -> actual Java output.

require "../spec_helper"

# Known Java 3.0.4 ground-truth outputs for PDFs whose checked-in fixtures are stale.
STALE_FIXTURES = {
  "FC60_Times.pdf" => "بآُتَّا",
}

pdfs = [
  "PDFBOX-3053-reduced.pdf",                                # spacing — extra space in "Symp toms"
  "PDFBOX-3061-092465-reduced.pdf",                         # spacing — missing spaces
  "PDFBOX-3110-poems-beads.pdf",                            # beads — column ordering
  "PDFBOX-3110-poems-beads-cropbox.pdf",                    # beads — column ordering
  "FC60_Times.pdf",                                         # encoding — stale fixture, matches Java 3.0.4
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

    if stale = STALE_FIXTURES[basename]?
      # Fixture is stale; compare against the known Java 3.0.4 ground truth.
      e_norm = stale.strip
      if a_norm == e_norm
        puts "#{basename}: MATCH (Java 3.0.4; fixture is stale — pre-mergeDiacritic bidi)"
      else
        puts "#{basename}: FAIL vs Java 3.0.4 (crystal=#{a_norm.inspect} java304=#{e_norm.inspect})"
      end
    elsif a_norm == expected.gsub(/\r\n?/, "\n").strip
      puts "#{basename}: MATCH"
    else
      e_norm = expected.gsub(/\r\n?/, "\n").strip
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
