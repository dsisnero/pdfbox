require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Type
    describe "Simple metadata properties" do
      parent = XMPMetadata.create_xmp_metadata

      it "detects bad boolean type" do
        expect_raises(ArgumentError) do
          BooleanType.new(parent, nil, "test", "boolean", "Not a Boolean")
        end
      end

      it "detects bad date type" do
        expect_raises(ArgumentError) do
          DateType.new(parent, nil, "test", "date", "Bad Date")
        end
        date = DateType.new(parent, nil, "test", "date", "")
        expect_raises(ArgumentError) { date.value = nil }
        expect_raises(ArgumentError) { date.value = 3 }
      end

      it "detects bad integer type" do
        expect_raises(ArgumentError) do
          IntegerType.new(parent, nil, "test", "integer", "Not an int")
        end
      end

      it "detects bad real type" do
        expect_raises(ArgumentError) do
          RealType.new(parent, nil, "test", "real", "Not a real")
        end
      end

      it "detects bad text type" do
        expect_raises(ArgumentError) do
          TextType.new(parent, nil, "test", "text", Time.utc)
        end
      end

      it "synchronizes element and object" do
        boolv = true
        datev = Time.utc
        integerv = 1
        realv = 1.69
        textv = "TEXTCONTENT"

        tm = parent.type_mapping
        bool = tm.create_boolean(nil, "test", "boolean", boolv)
        date = tm.create_date(nil, "test", "date", datev)
        integer = tm.create_integer(nil, "test", "integer", integerv)
        real = tm.create_real(nil, "test", "real", realv)
        text = tm.create_text(nil, "test", "text", textv)

        bool.value.should eq(boolv)
        date.value.should eq(datev)
        integer.value.should eq(integerv)
        (real.value.not_nil! - realv).abs.should be < 0.0001
        text.string_value.should eq(textv)
      end

      it "creates from native values" do
        # Crystal types accept native values (Bool, Int, Float, String)
        # Java also accepts String representations; not yet ported
        boolv = false
        datev = "2010-03-22T14:33:11+01:00"
        integerv = 10
        realv = 1.92
        textv = "text"

        bool = BooleanType.new(parent, nil, "test", "boolean", boolv)
        date = DateType.new(parent, nil, "test", "date", datev)
        integer = IntegerType.new(parent, nil, "test", "integer", integerv)
        real = RealType.new(parent, nil, "test", "real", realv)
        text = TextType.new(parent, nil, "test", "text", textv)

        bool.string_value.should eq(boolv.to_s)
        date.string_value.should eq(datev)
        integer.string_value.should eq(integerv.to_s)
        real.string_value.should eq(realv.to_s)
        text.string_value.should eq(textv)
      end

      it "creates objects with namespace" do
        ns = "http://www.test.org/pdfa/"
        tm = parent.type_mapping
        bool = tm.create_boolean(ns, "test", "boolean", true)
        date = tm.create_date(ns, "test", "date", Time.utc)
        integer = tm.create_integer(ns, "test", "integer", 1)
        real = tm.create_real(ns, "test", "real", 1.6)
        text = tm.create_text(ns, "test", "text", "TEST")

        bool.namespace.should eq(ns)
        date.namespace.should eq(ns)
        integer.namespace.should eq(ns)
        real.namespace.should eq(ns)
        text.namespace.should eq(ns)
      end

      it "manages attributes" do
        integer = IntegerType.new(parent, nil, "test", "integer", 1)
        value = Attribute.new("http://www.test.org/test/", "value1", "StringValue1")
        value2 = Attribute.new("http://www.test.org/test/", "value2", "StringValue2")

        integer.attribute = value
        integer.attribute(value.name).should eq(value)
        integer.contains_attribute?(value.name).should be_true

        # Replacement check
        integer.attribute = value2
        integer.attribute(value2.name).should eq(value2)

        integer.remove_attribute(value2.name)
        integer.contains_attribute?(value2.name).should be_false

        # Attribute with namespace creation
        value_ns = Attribute.new("http://www.tefst2.org/test/", "value2", "StringValue.2")
        integer.attribute = value_ns
        value_ns2 = Attribute.new("http://www.test2.org/test/", "value2", "StringValueTwo")
        integer.attribute = value_ns2

        atts = integer.all_attributes
        atts.includes?(value_ns).should be_false
        atts.includes?(value_ns2).should be_true
      end
    end
  end
end
