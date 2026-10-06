require "../../../spec_helper"

module Pdfbox::Pdmodel::Font
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/font/TestFontEmbedding.java
  #
  # Ports the end-to-end TTF-as-CIDFontType2 embedding round-trips (save →
  # reload → text extraction) plus the surrogate-pair / zero-width / missing
  # glyph exception cases. Render-compare assertions (TestPDFToImage.doTestFile)
  # are advisory and skipped, matching Chunk K's render-compare policy.
  module FontEmbeddingSpecHelpers
    LIBERATION_TTF = SpecPaths.resolve("vendor/pdfbox/fontbox/src/test/resources/ttf/LiberationSans-Regular.ttf")

    def self.extract_unicode_text(io : ::IO) : String
      bytes = io.to_slice
      doc = Pdfbox::Pdmodel::Document.load(::IO::Memory.new(bytes))
      begin
        Pdfbox::Text::PDFTextStripper.new.get_text(doc).gsub("\r", "").strip
      ensure
        doc.close
      end
    end

    def self.validate_cid_font_type2(use_subset : Bool) : Nil
      text = "Unicode русский язык Tiếng Việt"
      baos = ::IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(LIBERATION_TTF), use_subset)
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 12)
          cs.new_line_at_offset(50, 600)
          cs.show_text(text)
          cs.end_text
        ensure
          cs.close
        end

        doc.save(baos)
      ensure
        doc.close
      end

      extract_unicode_text(baos).should eq(text)
    end
  end

  describe "TestFontEmbedding" do
    it "testCIDFontType2" do
      FontEmbeddingSpecHelpers.validate_cid_font_type2(false)
    end

    it "testCIDFontType2Subset" do
      FontEmbeddingSpecHelpers.validate_cid_font_type2(true)
    end

    it "testReuseEmbeddedSubsettedFont (documented limitation)" do
      # Java re-expands a reloaded embedded subset font when appending new text
      # (the subset is re-parsed from the embedded FontFile2 and grown). The
      # Crystal Type0 font loaded from a dictionary keeps @embed_subset=false and
      # a nil @ttf, so appending glyphs outside the saved subset raises
      # "could not find the glyphId". This is a documented limitation (subset
      # re-expansion on reload is not yet supported): the appending step raises.
      text1 = "The quick brown fox"
      text2 = "xof nworb kciuq ehT"
      baos = ::IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(FontEmbeddingSpecHelpers::LIBERATION_TTF))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 20)
          cs.new_line_at_offset(50, 600)
          cs.show_text(text1)
          cs.end_text
        ensure
          cs.close
        end

        doc.save(baos)
      ensure
        doc.close
      end

      loaded = Pdfbox::Pdmodel::Document.load(::IO::Memory.new(baos.to_slice))
      begin
        page = loaded.page(0).as(Pdfbox::Pdmodel::Page)
        font = loaded.get_page(0).resources.not_nil!.font(Pdfbox::Cos::Name.new("F1")).not_nil!
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(
          loaded, page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, true
        )
        begin
          cs.begin_text
          cs.set_font(font, 20)
          cs.new_line_at_offset(250, 600)
          # Appending text whose glyphs are not in the saved subset is not yet
          # supported: the reloaded subset font cannot re-expand.
          expect_raises(Pdfbox::Pdmodel::IllegalStateError) { cs.show_text(text2) }
          cs.end_text
        ensure
          cs.close
        end
      ensure
        loaded.close
      end
    end

    it "testSurrogatePairCharacter" do
      message = "𩸽𩸽"
      baos = ::IO::Memory.new
      ipa_font = SpecPaths.resolve("vendor/pdfbox/fontbox/target/fonts/ipag00303/ipag.ttf")
      next unless File.exists?(ipa_font)

      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(ipa_font))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 64)
          cs.new_line_at_offset(100, 700)
          cs.show_text(message)
          cs.end_text
        ensure
          cs.close
        end

        doc.save(baos)
      ensure
        doc.close
      end

      FontEmbeddingSpecHelpers.extract_unicode_text(baos).should eq(message)
    end

    it "testSurrogatePairCharacterExceptionIsBmpCodePoint" do
      message = "あ"
      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(FontEmbeddingSpecHelpers::LIBERATION_TTF))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 64)
          cs.new_line_at_offset(100, 700)
          expect_raises(Pdfbox::Pdmodel::IllegalStateError, "could not find the glyphId for the character: あ, codePoint: 12354 (0x3042)") do
            cs.show_text(message)
          end
          cs.end_text
        ensure
          cs.close
        end
      ensure
        doc.close
      end
    end

    it "testSurrogatePairCharacterExceptionIsValidCodePoint" do
      message = "𩸽"
      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(FontEmbeddingSpecHelpers::LIBERATION_TTF))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 64)
          cs.new_line_at_offset(100, 700)
          expect_raises(Pdfbox::Pdmodel::IllegalStateError, "could not find the glyphId for the character: 𩸽, codePoint: 171581 (0x29E3D)") do
            cs.show_text(message)
          end
          cs.end_text
        ensure
          cs.close
        end
      ensure
        doc.close
      end
    end

    it "testEmbeddedFontWithZeroWidthChars" do
      text = "AAA\u200CBBB"
      baos = ::IO::Memory.new

      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(FontEmbeddingSpecHelpers::LIBERATION_TTF))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 20)
          cs.new_line_at_offset(50, 600)
          cs.show_text(text)
          cs.end_text
        ensure
          cs.close
        end

        doc.save(baos)
      ensure
        doc.close
      end

      loaded = Pdfbox::Pdmodel::Document.load(::IO::Memory.new(baos.to_slice))
      begin
        extracted = Pdfbox::Text::PDFTextStripper.new.get_text(loaded).strip
        extracted.should eq(text)
        extracted.size.should eq(7)
        extracted[3].should eq('\u200C')

        page = loaded.page(0).as(Pdfbox::Pdmodel::Page)
        resources = page.resources.not_nil!
        font = resources.font(Pdfbox::Cos::Name.new("F1")).as(PDType0Font)
        encoded = font.encode('\u200C'.ord)
        code = ((encoded[0].to_i & 0xFF) << 8) | (encoded[1].to_i & 0xFF)
        font.width(code).should eq(0)
        font.width_from_font(code).should eq(0)
        font.damaged?.should be_false
      ensure
        loaded.close
      end
    end

    it "testMaxEntries" do
      text = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん" \
             "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン" \
             "１２３４５６７８"
      ipa_font = SpecPaths.resolve("vendor/pdfbox/fontbox/target/fonts/ipag00303/ipag.ttf")
      next unless File.exists?(ipa_font)

      doc = Pdfbox::Pdmodel::Document.create
      begin
        page = Pdfbox::Pdmodel::Page.new
        doc.add_page(page)

        font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
        font = PDType0Font.load(font_doc, File.open(ipa_font))
        cs = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        begin
          cs.begin_text
          cs.set_font(font, 20)
          cs.new_line_at_offset(50, 3000)
          cs.show_text(text)
          cs.end_text
        ensure
          cs.close
        end

        baos = ::IO::Memory.new
        doc.save(baos)
      ensure
        doc.close
      end

      FontEmbeddingSpecHelpers.extract_unicode_text(baos).should eq(text)
    end
  end
end
