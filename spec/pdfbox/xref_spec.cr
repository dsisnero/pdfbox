require "../spec_helper"

describe Pdfbox::Pdfparser::XRef do
  describe ".new" do
    it "creates an empty xref table" do
      xref = Pdfbox::Pdfparser::XRef.new
      xref.size.should eq(0)
    end
  end

  describe "#[]" do
    it "returns nil for non-existent object number" do
      xref = Pdfbox::Pdfparser::XRef.new
      xref[1].should be_nil
    end
  end

  describe "#[]=" do
    it "adds an entry to the xref table" do
      xref = Pdfbox::Pdfparser::XRef.new
      entry = Pdfbox::Pdfparser::XRefEntry.new(100_i64, 0_i64, :in_use)
      xref[1] = entry
      xref[1].should eq(entry)
      xref.size.should eq(1)
    end
  end

  describe "#entries" do
    it "returns all entries" do
      xref = Pdfbox::Pdfparser::XRef.new
      entry1 = Pdfbox::Pdfparser::XRefEntry.new(100_i64, 0_i64, :in_use)
      entry2 = Pdfbox::Pdfparser::XRefEntry.new(200_i64, 1_i64, :free)
      xref[1] = entry1
      xref[2] = entry2
      entries = xref.entries
      entries[1].should eq(entry1)
      entries[2].should eq(entry2)
    end
  end
end

describe Pdfbox::Pdfparser::XRefEntry do
  describe ".new" do
    it "creates an in-use entry" do
      entry = Pdfbox::Pdfparser::XRefEntry.new(100_i64, 0_i64, :in_use)
      entry.offset.should eq(100_i64)
      entry.generation.should eq(0_i64)
      entry.type.should eq(:in_use)
      entry.in_use?.should be_true
      entry.free?.should be_false
    end

    it "creates a free entry" do
      entry = Pdfbox::Pdfparser::XRefEntry.new(200_i64, 1_i64, :free)
      entry.type.should eq(:free)
      entry.free?.should be_true
      entry.in_use?.should be_false
    end
  end
end

describe Pdfbox::Pdfparser::Parser do
  describe "#parse_xref" do
    it "parses a simple xref table" do
      # Simple xref table format:
      # xref
      # 0 2
      # 0000000000 65535 f
      # 0000000010 00000 n
      xref_data = "xref\n0 2\n0000000000 65535 f\n0000000010 00000 n\n"
      source = Pdfbox::IO::MemoryRandomAccessRead.new(xref_data.to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)

      xref = parser.parse_xref
      xref.should_not be_nil
      xref.size.should eq(2)

      # Check free entry (object 0)
      entry0 = xref[0]
      entry0.should_not be_nil
      entry0.not_nil!.offset.should eq(0_i64)
      entry0.not_nil!.generation.should eq(65535_i64)
      entry0.not_nil!.type.should eq(:free)

      # Check in-use entry (object 1)
      entry1 = xref[1]
      entry1.should_not be_nil
      entry1.not_nil!.offset.should eq(10_i64)
      entry1.not_nil!.generation.should eq(0_i64)
      entry1.not_nil!.type.should eq(:in_use)
    end

    it "parses xref with multiple subsections" do
      # xref with subsections:
      # xref
      # 0 1
      # 0000000000 65535 f
      # 3 2
      # 0000000100 00000 n
      # 0000000200 00001 n
      xref_data = "xref\n0 1\n0000000000 65535 f\n3 2\n0000000100 00000 n\n0000000200 00001 n\n"
      source = Pdfbox::IO::MemoryRandomAccessRead.new(xref_data.to_slice)
      parser = Pdfbox::Pdfparser::Parser.new(source)

      xref = parser.parse_xref
      xref.size.should eq(3)

      xref[0].not_nil!.type.should eq(:free)
      xref[3].not_nil!.offset.should eq(100_i64)
      xref[4].not_nil!.offset.should eq(200_i64)
      xref[4].not_nil!.generation.should eq(1_i64)
    end
  end
end

describe Pdfbox::Pdfwriter::XRefWriter do
  describe "#write" do
    it "writes a simple xref table" do
      io = IO::Memory.new
      writer = Pdfbox::Pdfwriter::XRefWriter.new(io)

      # Add entries
      writer.add_entry(0_i64, 65535_i64, :free)
      writer.add_entry(10_i64, 0_i64, :in_use)

      writer.write

      output = io.to_s
      output.should contain("xref\n")
      output.should contain("0000000000 65535 f")
      output.should contain("0000000010 00000 n")
    end
  end
end
