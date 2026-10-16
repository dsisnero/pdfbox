require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSDocument.java
# Characterization spec for the COSDocument accessor surface (upstream has no
# dedicated COSDocument test).
module Pdfbox
  module Cos
    describe Document do
      it "tracks the header version and startxref" do
        doc = Document.new
        doc.version.should eq(0.0_f32)
        doc.version = 1.6_f32
        doc.version.should eq(1.6_f32)

        doc.start_xref.should eq(0_i64)
        doc.start_xref = 42_i64
        doc.start_xref.should eq(42_i64)
      end

      it "tracks the xref stream and hybrid xref flags" do
        doc = Document.new
        doc.is_xref_stream?.should be_false
        doc.is_xref_stream = true
        doc.is_xref_stream?.should be_true

        doc.has_hybrid_xref?.should be_false
        doc.has_hybrid_xref = true
        doc.has_hybrid_xref?.should be_true
      end

      it "reports encryption via the trailer dictionary" do
        doc = Document.new
        doc.trailer = Dictionary.new
        doc.encrypted?.should be_false

        enc = Dictionary.new
        doc.encryption_dictionary = enc
        doc.encrypted?.should be_true
        doc.encryption_dictionary.should eq(enc)
      end

      it "tracks the decrypted flag" do
        doc = Document.new
        doc.decrypted?.should be_false
        doc.set_decrypted
        doc.decrypted?.should be_true
      end

      it "reads and writes the document id through the trailer" do
        doc = Document.new
        doc.trailer = Dictionary.new
        doc.document_id.should be_nil

        id = Array.new
        id.add(String.new("abc"))
        doc.document_id = id
        doc.document_id.should eq(id)
      end

      it "tracks the highest xref object number" do
        doc = Document.new
        doc.highest_xref_object_number.should eq(0_i64)
        doc.highest_xref_object_number = 12_i64
        doc.highest_xref_object_number.should eq(12_i64)
      end

      it "closes exactly once" do
        doc = Document.new
        doc.closed?.should be_false
        doc.close
        doc.closed?.should be_true
      end

      it "exposes a memory-backed stream cache" do
        doc = Document.new
        doc.stream_cache.should be_a(Pdfbox::IO::RandomAccessStreamCacheImpl)

        replacement = Pdfbox::IO::RandomAccessStreamCacheImpl.new
        doc.stream_cache = replacement
        doc.stream_cache.should eq(replacement)
      end

      it "returns a proxy object from the pool" do
        doc = Document.new
        key = ObjectKey.new(5_i64, 0_i64)

        object = doc.object_from_pool(key)
        object.should_not be_nil
        object.not_nil!.object_number.should eq(5_i64)

        # a second lookup returns the same pooled object
        doc.object_from_pool(key).should eq(object)
      end

      it "returns the xref table" do
        doc = Document.new
        doc.xref_table.should be_empty

        doc.add_xref_table({ObjectKey.new(1_i64, 0_i64) => 10_i64})
        doc.xref_table.size.should eq(1)
      end
    end
  end
end
