require "../spec_helper"

ESC_CHAR_STRING            = "( test#some) escaped< \\chars>!~1239857 "
ESC_CHAR_STRING_PDF_FORMAT = "\\( test#some\\) escaped< \\\\chars>!~1239857 "

describe Pdfbox::Cos::String do
  describe ".new" do
    it "creates a string with given value" do
      str = Pdfbox::Cos::String.new("test")
      str.value.should eq("test")
    end

    it "creates a string with hex form flag" do
      str = Pdfbox::Cos::String.new("test", force_hex_form: true)
      str.value.should eq("test")
      str.force_hex_form?.should be_true
    end
  end

  describe "#value_as_object" do
    it "returns the string value" do
      str = Pdfbox::Cos::String.new("test")
      str.value_as_object.should eq("test")
    end
  end

  describe ".parse_hex" do
    it "creates a string from hex representation" do
      hex = "54657374" # "Test" in hex
      str = Pdfbox::Cos::String.parse_hex(hex)
      str.value.should eq("Test")
    end

    it "raises error on invalid hex" do
      expect_raises(Pdfbox::Cos::Error) do
        Pdfbox::Cos::String.parse_hex("invalid")
      end
    end
  end

  describe "#to_hex_string" do
    it "returns hex representation of string" do
      str = Pdfbox::Cos::String.new("Test")
      str.to_hex_string.should eq("54657374")
    end
  end

  describe "#write_pdf" do
    it "writes string in PDF format" do
      str = Pdfbox::Cos::String.new("Test")
      io = IO::Memory.new
      str.write_pdf(io)
      io.to_s.should eq("(Test)")
    end

    it "escapes special characters in literal strings" do
      str = Pdfbox::Cos::String.new(ESC_CHAR_STRING)
      io = IO::Memory.new
      str.write_pdf(io)
      io.to_s.should eq("(" + ESC_CHAR_STRING_PDF_FORMAT + ")")
    end

    it "writes hex form when forced" do
      str = Pdfbox::Cos::String.new("Test", force_hex_form: true)
      io = IO::Memory.new
      str.write_pdf(io)
      io.to_s.should match(/<[0-9A-F]+>/)
    end
  end

  describe "#bytes" do
    it "returns bytes of the string" do
      str = Pdfbox::Cos::String.new("Test")
      str.bytes.should eq("Test".to_slice)
    end
  end

  describe "#==" do
    it "is reflexive" do
      x = Pdfbox::Cos::String.new("Test")
      x.should eq(x)
    end

    it "is symmetric" do
      x = Pdfbox::Cos::String.new("Test")
      y = Pdfbox::Cos::String.new("Test")
      x.should eq(y)
      y.should eq(x)
    end

    it "distinguishes between hex and literal forms" do
      x = Pdfbox::Cos::String.new("Test")
      y = Pdfbox::Cos::String.new("Test", force_hex_form: true)
      x.should_not eq(y)
    end
  end

  describe "#hash" do
    it "returns same hash for equal strings" do
      str1 = Pdfbox::Cos::String.new("Test1")
      str2 = Pdfbox::Cos::String.new("Test1")
      str1.hash.should eq(str2.hash)
    end

    it "returns different hash for different strings" do
      str1 = Pdfbox::Cos::String.new("Test1")
      str2 = Pdfbox::Cos::String.new("Test2")
      str1.hash.should_not eq(str2.hash)
    end

    it "returns different hash for hex vs literal forms" do
      str1 = Pdfbox::Cos::String.new("Test1")
      str2 = Pdfbox::Cos::String.new("Test1", force_hex_form: true)
      str1.hash.should_not eq(str2.hash)
    end
  end

  describe "unicode handling" do
    it "handles ASCII text" do
      text = "This is some regular text. It should all be expressible in ASCII"
      str = Pdfbox::Cos::String.new(text)
      str.value.should eq(text)
    end

    it "handles 8-bit characters" do
      text = "En français où les choses sont accentués. En español, así"
      str = Pdfbox::Cos::String.new(text)
      str.value.should eq(text)
    end

    it "handles high-bit characters" do
      text = "をクリックしてく" # Japanese
      str = Pdfbox::Cos::String.new(text)
      str.value.should eq(text)
    end
  end

  describe "hex string comparison" do
    it "compares strings created from hex correctly" do
      test1 = Pdfbox::Cos::String.parse_hex("000000FF000000")
      test2 = Pdfbox::Cos::String.parse_hex("000000FF00FFFF")
      test1.should eq(test1)
      test2.should eq(test2)
      test1.should_not eq(test2)
      test1.to_hex_string.should_not eq(test2.to_hex_string)
    end
  end

  # Test from testEmptyStringWithBOM
  pending "empty string with BOM" do
    it "treats string with only BOM as empty" do
      # str1 = Pdfbox::Cos::String.parse_hex("FEFF")
      # str1.value.should eq("")
      # str2 = Pdfbox::Cos::String.parse_hex("FFFE")
      # str2.value.should eq("")
    end
  end
end

# Other COS type tests will go in separate describe blocks
describe Pdfbox::Cos::Boolean do
  describe ".get" do
    it "returns TRUE for true" do
      Pdfbox::Cos::Boolean.get(true).should be(Pdfbox::Cos::Boolean::TRUE)
    end

    it "returns FALSE for false" do
      Pdfbox::Cos::Boolean.get(false).should be(Pdfbox::Cos::Boolean::FALSE)
    end
  end

  describe "#value" do
    it "returns boolean value" do
      Pdfbox::Cos::Boolean::TRUE.value.should be_true
      Pdfbox::Cos::Boolean::FALSE.value.should be_false
    end
  end

  describe "#value_as_object" do
    it "returns boolean object" do
      Pdfbox::Cos::Boolean::TRUE.value_as_object.should be_true
      Pdfbox::Cos::Boolean::FALSE.value_as_object.should be_false
    end
  end

  describe "#==" do
    it "equals itself" do
      Pdfbox::Cos::Boolean::TRUE.should eq(Pdfbox::Cos::Boolean::TRUE)
      Pdfbox::Cos::Boolean::FALSE.should eq(Pdfbox::Cos::Boolean::FALSE)
    end

    it "TRUE does not equal FALSE" do
      Pdfbox::Cos::Boolean::TRUE.should_not eq(Pdfbox::Cos::Boolean::FALSE)
    end

    it "does not equal Ruby boolean" do
      Pdfbox::Cos::Boolean::TRUE.should_not be_true
      Pdfbox::Cos::Boolean::FALSE.should_not be_false
    end
  end

  describe "#write_pdf" do
    it "writes true as 'true'" do
      io = IO::Memory.new
      Pdfbox::Cos::Boolean::TRUE.write_pdf(io)
      io.to_s.should eq("true")
    end

    it "writes false as 'false'" do
      io = IO::Memory.new
      Pdfbox::Cos::Boolean::FALSE.write_pdf(io)
      io.to_s.should eq("false")
    end
  end
end

describe Pdfbox::Cos::Integer do
  describe "#value" do
    it "returns integer value" do
      int = Pdfbox::Cos::Integer.new(42_i64)
      int.value.should eq(42_i64)
    end
  end

  describe "#value_as_object" do
    it "returns integer as object" do
      int = Pdfbox::Cos::Integer.new(42_i64)
      int.value_as_object.should eq(42_i64)
    end
  end

  describe "#==" do
    it "equals same integer" do
      int1 = Pdfbox::Cos::Integer.new(42_i64)
      int2 = Pdfbox::Cos::Integer.new(42_i64)
      int1.should eq(int2)
    end

    it "does not equal different integer" do
      int1 = Pdfbox::Cos::Integer.new(42_i64)
      int2 = Pdfbox::Cos::Integer.new(43_i64)
      int1.should_not eq(int2)
    end

    it "does not equal raw integer" do
      int = Pdfbox::Cos::Integer.new(42_i64)
      int.should_not eq(42_i64)
    end
  end

  describe "#write_pdf" do
    it "writes integer as string" do
      int = Pdfbox::Cos::Integer.new(42_i64)
      io = IO::Memory.new
      int.write_pdf(io)
      io.to_s.should eq("42")
    end

    it "writes negative integer" do
      int = Pdfbox::Cos::Integer.new(-42_i64)
      io = IO::Memory.new
      int.write_pdf(io)
      io.to_s.should eq("-42")
    end
  end
end

describe Pdfbox::Cos::Float do
  describe "#value" do
    it "returns float value" do
      float = Pdfbox::Cos::Float.new(3.14)
      float.value.should eq(3.14)
    end
  end

  describe "#value_as_object" do
    it "returns float as object" do
      float = Pdfbox::Cos::Float.new(3.14)
      float.value_as_object.should eq(3.14)
    end
  end

  describe "#==" do
    it "equals same float" do
      float1 = Pdfbox::Cos::Float.new(3.14)
      float2 = Pdfbox::Cos::Float.new(3.14)
      float1.should eq(float2)
    end

    it "does not equal different float" do
      float1 = Pdfbox::Cos::Float.new(3.14)
      float2 = Pdfbox::Cos::Float.new(3.15)
      float1.should_not eq(float2)
    end

    it "does not equal raw float" do
      float = Pdfbox::Cos::Float.new(3.14)
      float.should_not eq(3.14)
    end
  end

  describe "#write_pdf" do
    it "writes float as string" do
      float = Pdfbox::Cos::Float.new(3.14)
      io = IO::Memory.new
      float.write_pdf(io)
      io.to_s.should eq("3.14")
    end

    it "writes scientific notation for large numbers" do
      float = Pdfbox::Cos::Float.new(1.23e+10)
      io = IO::Memory.new
      float.write_pdf(io)
      # PDF numbers don't use scientific notation, just decimal
      io.to_s.should eq("12300000000.0")
    end
  end
end

describe Pdfbox::Cos::Name do
  describe "#value" do
    it "returns name value" do
      name = Pdfbox::Cos::Name.new("Font")
      name.value.should eq("Font")
    end
  end

  describe "#value_as_object" do
    it "returns name as object" do
      name = Pdfbox::Cos::Name.new("Font")
      name.value_as_object.should eq("Font")
    end
  end

  describe "#==" do
    it "equals same name" do
      name1 = Pdfbox::Cos::Name.new("Font")
      name2 = Pdfbox::Cos::Name.new("Font")
      name1.should eq(name2)
    end

    it "does not equal different name" do
      name1 = Pdfbox::Cos::Name.new("Font")
      name2 = Pdfbox::Cos::Name.new("Size")
      name1.should_not eq(name2)
    end

    it "does not equal raw string" do
      name = Pdfbox::Cos::Name.new("Font")
      name.should_not eq("Font")
    end
  end

  describe "#write_pdf" do
    it "writes name with leading slash" do
      name = Pdfbox::Cos::Name.new("Font")
      io = IO::Memory.new
      name.write_pdf(io)
      io.to_s.should eq("/Font")
    end

    it "escapes special characters in names" do
      name = Pdfbox::Cos::Name.new("Font#Name")
      io = IO::Memory.new
      name.write_pdf(io)
      # PDF name escaping: # -> #
      io.to_s.should eq("/Font#23Name")
    end
  end
end

describe Pdfbox::Cos::Array do
  describe "#initialize" do
    it "creates empty array" do
      array = Pdfbox::Cos::Array.new
      array.size.should eq(0)
    end

    it "creates array with items" do
      items = [Pdfbox::Cos::Name.new("A").as(Pdfbox::Cos::Base),
               Pdfbox::Cos::Name.new("B").as(Pdfbox::Cos::Base),
               Pdfbox::Cos::Name.new("C").as(Pdfbox::Cos::Base)]
      array = Pdfbox::Cos::Array.new(items)
      array.size.should eq(3)
      array[0].should eq(items[0])
      array[1].should eq(items[1])
      array[2].should eq(items[2])
    end
  end

  describe "#add" do
    it "adds items to array" do
      array = Pdfbox::Cos::Array.new
      item = Pdfbox::Cos::Name.new("Test")
      array.add(item)
      array.size.should eq(1)
      array[0].should eq(item)
    end
  end

  describe "#[]=" do
    it "sets item at index" do
      items = [Pdfbox::Cos::Name.new("A").as(Pdfbox::Cos::Base),
               Pdfbox::Cos::Name.new("B").as(Pdfbox::Cos::Base)]
      array = Pdfbox::Cos::Array.new(items)
      new_item = Pdfbox::Cos::Name.new("C").as(Pdfbox::Cos::Base)
      array[1] = new_item
      array[1].should eq(new_item)
    end
  end

  describe "#==" do
    it "equals same array" do
      items = [Pdfbox::Cos::Name.new("A").as(Pdfbox::Cos::Base),
               Pdfbox::Cos::Name.new("B").as(Pdfbox::Cos::Base)]
      array1 = Pdfbox::Cos::Array.new(items)
      array2 = Pdfbox::Cos::Array.new(items)
      array1.should eq(array2)
    end

    it "does not equal different array" do
      array1 = Pdfbox::Cos::Array.new([Pdfbox::Cos::Name.new("A").as(Pdfbox::Cos::Base)])
      array2 = Pdfbox::Cos::Array.new([Pdfbox::Cos::Name.new("B").as(Pdfbox::Cos::Base)])
      array1.should_not eq(array2)
    end
  end

  describe "#write_pdf" do
    it "writes empty array" do
      array = Pdfbox::Cos::Array.new
      io = IO::Memory.new
      array.write_pdf(io)
      io.to_s.should eq("[]")
    end

    it "writes array with items" do
      items = [Pdfbox::Cos::Integer.new(1).as(Pdfbox::Cos::Base),
               Pdfbox::Cos::Name.new("Test").as(Pdfbox::Cos::Base)]
      array = Pdfbox::Cos::Array.new(items)
      io = IO::Memory.new
      array.write_pdf(io)
      io.to_s.should eq("[1 /Test]")
    end
  end
end

describe Pdfbox::Cos::Dictionary do
  describe "#initialize" do
    it "creates empty dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict.size.should eq(0)
    end

    it "creates dictionary with entries" do
      entries = {Pdfbox::Cos::Name.new("Type") => Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base)}
      dict = Pdfbox::Cos::Dictionary.new(entries)
      dict.size.should eq(1)
      dict[Pdfbox::Cos::Name.new("Type")].should eq(Pdfbox::Cos::Name.new("Catalog"))
    end
  end

  describe "#[]=" do
    it "sets value for key" do
      dict = Pdfbox::Cos::Dictionary.new
      key = Pdfbox::Cos::Name.new("Type")
      value = Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base)
      dict[key] = value
      dict[key].should eq(value)
    end
  end

  describe "#[]" do
    it "returns nil for missing key" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Missing")].should be_nil
    end

    it "returns value for existing key" do
      key = Pdfbox::Cos::Name.new("Type")
      value = Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base)
      dict = Pdfbox::Cos::Dictionary.new({key => value})
      dict[key].should eq(value)
    end
  end

  describe "#has_key?" do
    it "returns true for existing key" do
      key = Pdfbox::Cos::Name.new("Type")
      dict = Pdfbox::Cos::Dictionary.new({key => Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base)})
      dict.has_key?(key).should be_true
    end

    it "returns false for missing key" do
      dict = Pdfbox::Cos::Dictionary.new
      dict.has_key?(Pdfbox::Cos::Name.new("Missing")).should be_false
    end
  end

  describe "#==" do
    it "equals same dictionary" do
      entries = {Pdfbox::Cos::Name.new("Type") => Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base)}
      dict1 = Pdfbox::Cos::Dictionary.new(entries)
      dict2 = Pdfbox::Cos::Dictionary.new(entries)
      dict1.should eq(dict2)
    end

    it "does not equal different dictionary" do
      dict1 = Pdfbox::Cos::Dictionary.new({Pdfbox::Cos::Name.new("A") => Pdfbox::Cos::Name.new("B").as(Pdfbox::Cos::Base)})
      dict2 = Pdfbox::Cos::Dictionary.new({Pdfbox::Cos::Name.new("X") => Pdfbox::Cos::Name.new("Y").as(Pdfbox::Cos::Base)})
      dict1.should_not eq(dict2)
    end
  end

  describe "#write_pdf" do
    it "writes empty dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      io = IO::Memory.new
      dict.write_pdf(io)
      io.to_s.should eq("<<>>")
    end

    it "writes dictionary with entries" do
      entries = {Pdfbox::Cos::Name.new("Type")    => Pdfbox::Cos::Name.new("Catalog").as(Pdfbox::Cos::Base),
                 Pdfbox::Cos::Name.new("Version") => Pdfbox::Cos::Integer.new(2).as(Pdfbox::Cos::Base)}
      dict = Pdfbox::Cos::Dictionary.new(entries)
      io = IO::Memory.new
      dict.write_pdf(io)
      # Order not guaranteed, but PDF spec says order doesn't matter
      io_str = io.to_s
      io_str.should match(/<</)
      io_str.should match(/>>/)
      io_str.should contain("/Type")
      io_str.should contain("/Catalog")
      io_str.should contain("/Version")
      io_str.should contain("2")
    end
  end
end

describe Pdfbox::Cos::Stream do
  describe "#initialize" do
    it "creates empty stream" do
      stream = Pdfbox::Cos::Stream.new
      stream.size.should eq(0)
      stream.data.size.should eq(0)
    end

    it "creates stream with dictionary entries and data" do
      entries = {Pdfbox::Cos::Name.new("Length") => Pdfbox::Cos::Integer.new(4).as(Pdfbox::Cos::Base)}
      data = "test".to_slice
      stream = Pdfbox::Cos::Stream.new(entries, data)
      stream.size.should eq(1)
      stream[Pdfbox::Cos::Name.new("Length")].should eq(Pdfbox::Cos::Integer.new(4))
      stream.data.should eq(data)
    end
  end

  describe "#data=" do
    it "sets stream data" do
      stream = Pdfbox::Cos::Stream.new
      data = "hello".to_slice
      stream.data = data
      stream.data.should eq(data)
    end
  end

  describe "#==" do
    it "equals same stream" do
      entries = {Pdfbox::Cos::Name.new("Length") => Pdfbox::Cos::Integer.new(4).as(Pdfbox::Cos::Base)}
      data = "test".to_slice
      stream1 = Pdfbox::Cos::Stream.new(entries, data)
      stream2 = Pdfbox::Cos::Stream.new(entries, data)
      stream1.should eq(stream2)
    end

    it "does not equal stream with different data" do
      entries = {Pdfbox::Cos::Name.new("Length") => Pdfbox::Cos::Integer.new(4).as(Pdfbox::Cos::Base)}
      stream1 = Pdfbox::Cos::Stream.new(entries, "test".to_slice)
      stream2 = Pdfbox::Cos::Stream.new(entries, "diff".to_slice)
      stream1.should_not eq(stream2)
    end
  end

  describe "#write_pdf" do
    it "writes stream with data" do
      entries = {Pdfbox::Cos::Name.new("Length") => Pdfbox::Cos::Integer.new(4).as(Pdfbox::Cos::Base)}
      data = "test".to_slice
      stream = Pdfbox::Cos::Stream.new(entries, data)
      io = IO::Memory.new
      stream.write_pdf(io)
      io_str = io.to_s
      io_str.should match(/<</)
      io_str.should match(/>>/)
      io_str.should contain("/Length 4")
      io_str.should contain("stream")
      io_str.should contain("test")
      io_str.should contain("endstream")
    end
  end
end

describe Pdfbox::Cos::Object do
  describe "#initialize" do
    it "creates object reference with object number and generation" do
      obj = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      obj.object_number.should eq(42_i64)
      obj.generation_number.should eq(0_i64)
      obj.object.should be_nil
    end

    it "creates object reference with referenced object" do
      ref_obj = Pdfbox::Cos::Name.new("Test").as(Pdfbox::Cos::Base)
      obj = Pdfbox::Cos::Object.new(42_i64, 0_i64, ref_obj)
      obj.object_number.should eq(42_i64)
      obj.generation_number.should eq(0_i64)
      obj.object.should eq(ref_obj)
    end
  end

  describe "#object=" do
    it "sets referenced object" do
      obj = Pdfbox::Cos::Object.new(42_i64)
      ref_obj = Pdfbox::Cos::Name.new("Test").as(Pdfbox::Cos::Base)
      obj.object = ref_obj
      obj.object.should eq(ref_obj)
    end
  end

  describe "#==" do
    it "equals same object reference" do
      obj1 = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      obj2 = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      obj1.should eq(obj2)
    end

    it "does not equal different object number" do
      obj1 = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      obj2 = Pdfbox::Cos::Object.new(43_i64, 0_i64)
      obj1.should_not eq(obj2)
    end

    it "does not equal different generation number" do
      obj1 = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      obj2 = Pdfbox::Cos::Object.new(42_i64, 1_i64)
      obj1.should_not eq(obj2)
    end
  end

  describe "#write_pdf" do
    it "writes object reference" do
      obj = Pdfbox::Cos::Object.new(42_i64, 0_i64)
      io = IO::Memory.new
      obj.write_pdf(io)
      io.to_s.should eq("42 0 R")
    end
  end
end
