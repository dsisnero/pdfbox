require "../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/xref/
#   XReferenceEntry.java, AbstractXReference.java, XReferenceType.java,
#   FreeXReference.java, NormalXReference.java, ObjectStreamXReference.java
#
# These model classes back PDF cross-reference streams. There is no dedicated
# Java unit test file; the behavior is ported directly from the Java sources
# (column semantics per PDF 32000-1 table 18, compareTo/equality semantics,
# NULL_ENTRY constant, object-stream detection).

module Pdfbox::Pdfparser::Xref
  describe XReferenceType do
    it "maps numeric values to entry types" do
      XReferenceType::Free.numeric_value.should eq(0)
      XReferenceType::Normal.numeric_value.should eq(1)
      XReferenceType::ObjectStreamEntry.numeric_value.should eq(2)
    end

    it "converts from numeric value, returning nil for invalid" do
      XReferenceType.from_numeric_value(0).should eq(XReferenceType::Free)
      XReferenceType.from_numeric_value(1).should eq(XReferenceType::Normal)
      XReferenceType.from_numeric_value(2).should eq(XReferenceType::ObjectStreamEntry)
      XReferenceType.from_numeric_value(3).should be_nil
    end
  end

  describe FreeXReference do
    it "NULL_ENTRY is object 0, generation 65535" do
      FreeXReference::NULL_ENTRY.referenced_key.should eq(Cos::ObjectKey.new(0_i64, 65535_i64))
      FreeXReference::NULL_ENTRY.type.should eq(XReferenceType::Free)
    end

    it "reports columns: first=0, second=next free, third=generation" do
      entry = FreeXReference.new(Cos::ObjectKey.new(5_i64, 1_i64), 12_i64)
      entry.first_column_value.should eq(0)
      entry.second_column_value.should eq(12)
      entry.third_column_value.should eq(1)
      entry.next_free_object.should eq(12)
    end
  end

  describe NormalXReference do
    it "reports columns: first=1, second=byte offset, third=generation" do
      entry = NormalXReference.new(12345_i64, Cos::ObjectKey.new(7_i64, 0_i64))
      entry.type.should eq(XReferenceType::Normal)
      entry.first_column_value.should eq(1)
      entry.second_column_value.should eq(12345)
      entry.third_column_value.should eq(0)
      entry.byte_offset.should eq(12345)
      entry.object_stream?.should be_false
    end

    it "detects an object stream as the referenced object" do
      obj_stream = Pdfbox::Cos::Stream.new
      obj_stream[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("ObjStm")
      entry = NormalXReference.new(100_i64, Cos::ObjectKey.new(3_i64, 0_i64), obj_stream.as(Pdfbox::Cos::Base))
      entry.object_stream?.should be_true
    end

    it "returns the parsed object" do
      obj = Pdfbox::Cos::Integer.new(42)
      entry = NormalXReference.new(50_i64, Cos::ObjectKey.new(9_i64, 0_i64), obj.as(Pdfbox::Cos::Base))
      entry.object.should eq(obj)
    end
  end

  describe ObjectStreamXReference do
    it "reports columns: first=2, second=parent object stream, third=index" do
      entry = ObjectStreamXReference.new(3, Cos::ObjectKey.new(11_i64, 0_i64), Cos::ObjectKey.new(4_i64, 0_i64))
      entry.type.should eq(XReferenceType::ObjectStreamEntry)
      entry.first_column_value.should eq(2)
      entry.second_column_value.should eq(4)
      entry.third_column_value.should eq(3)
      entry.object_stream_index.should eq(3)
      entry.parent_key.should eq(Cos::ObjectKey.new(4_i64, 0_i64))
    end
  end

  describe XReferenceEntry do
    it "compares entries by referenced key (Java compareTo)" do
      low = NormalXReference.new(0_i64, Cos::ObjectKey.new(1_i64, 0_i64))
      high = NormalXReference.new(0_i64, Cos::ObjectKey.new(2_i64, 0_i64))
      low.should be < high
      high.should be > low
      low.should eq(NormalXReference.new(0_i64, Cos::ObjectKey.new(1_i64, 0_i64)))
    end

    it "compares across entry types by referenced key" do
      normal = NormalXReference.new(100_i64, Cos::ObjectKey.new(5_i64, 0_i64))
      free = FreeXReference.new(Cos::ObjectKey.new(5_i64, 0_i64), 0_i64)
      normal.should eq(free) # same referenced key
    end
  end
end
