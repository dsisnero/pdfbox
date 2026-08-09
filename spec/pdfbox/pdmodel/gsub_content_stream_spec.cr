require "../../spec_helper"

module Pdfbox::Pdmodel
  # Verifies the end-to-end GSUB wiring in PDPageContentStream: set_font creates
  # a GsubWorker for Type0 fonts with GSUB data, and show_text encodes text via
  # applyGSUBRules (glyph IDs transformed by the worker), matching Java's
  # PDAbstractContentStream.encodeForGsub / applyGSUBRules.
  describe PDPageContentStream do
    it "applies GSUB ligature substitution when showing text with a Type0 font" do
      font_path = "vendor/pdfbox/fontbox/src/test/resources/ttf/JosefinSans-Italic.ttf"
      temp_pdf = File.expand_path("../../../temp/gsub_test.pdf", __DIR__)

      font_doc = PDDocument.new(Bytes.new(0))
      font = File.open(font_path, "r") do |file|
        Font::PDType0Font.load(font_doc, file)
      end

      doc = Document.new
      begin
        page = Page.new
        doc.add_page(page)

        cs = PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 50)
          cs.new_line_at_offset(50, 700)
          cs.show_text("affine")
          cs.end_text
        ensure
          cs.close
        end

        File.open(temp_pdf, "w") { |file| doc.save(file) }

        loaded = Document.load(temp_pdf)
        begin
          page2 = loaded.pages[0]
          stream = page2.contents.as(Cos::Stream)
          filter = stream[Cos::Name.new("Filter")]?
          decoded = stream.decode_filters(stream.data, filter)

          # Extract the "( ... )" show-text literal and decode the 2-byte
          # big-endian glyph IDs. Each byte is a 3-digit octal escape, except a
          # literal space (0x20) which is written as a raw byte.
          arr = decoded.to_a
          lp = arr.index { |b| b == 40 }
          rp = arr.index { |b| b == 41 }
          lp.should_not be_nil
          rp.should_not be_nil

          literal = decoded[lp.not_nil! + 1, rp.not_nil! - lp.not_nil! - 1]
          bytes = [] of Int32
          j = 0
          while j < literal.size
            if literal[j] == 92 # backslash start of octal escape
              b = 0
              k = j + 1
              3.times do
                b = b * 8 + (literal[k] - 48)
                k += 1
              end
              bytes << b
              j = k
            else # raw byte (space)
              bytes << literal[j].to_i32
              j += 1
            end
          end
          bytes.size.even?.should be_true
          glyph_ids = bytes.each_slice(2).map { |pair| (pair[0] << 8) | pair[1] }.to_a

          # "affine" becomes 5 glyphs after GSUB ligature substitution
          glyph_ids.size.should eq(5)
          glyph_ids.should eq([203, 257, 407, 288, 237])
        ensure
          loaded.close
        end
      ensure
        doc.close
      end
    end
  end
end
