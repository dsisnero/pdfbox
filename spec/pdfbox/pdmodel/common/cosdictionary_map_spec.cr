require "../../../spec_helper"

module Pdfbox::Pdmodel::Common
  class TestCOSObjectable
    def cos_object : Cos::Base
      Cos::String.new("value")
    end
  end

  class WrapperTestCOSObjectable
    def initialize(@value : String); end

    def cos_object : Cos::Base
      Cos::String.new(@value)
    end
  end

  describe COSDictionaryMap do
    it "converts basic types to map" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("Name")] = Cos::Name.new("Test")
      dict[Cos::Name.new("Integer")] = Cos::Integer.new(42)
      dict[Cos::Name.new("Float")] = Cos::Float.new(3.14)
      dict[Cos::Name.new("String")] = Cos::String.new("Hello")
      dict[Cos::Name.new("Boolean")] = Cos::Boolean.get(true)

      map = COSDictionaryMap.convert_basic_types_to_map(dict)
      map.should_not be_nil
      map = map.not_nil!
      map["Name"].should eq "Test"
      map["Integer"].should eq 42_i64
      map["Float"].should eq 3.14
      map["String"].should eq "Hello"
      map["Boolean"].should be_true
    end

    it "converts map to dictionary" do
      some_map = {
        "key1" => TestCOSObjectable.new,
        "key2" => TestCOSObjectable.new,
      }
      dict = COSDictionaryMap.convert(some_map)
      dict.should be_a(Cos::Dictionary)
      dict[Cos::Name.new("key1")].should be_a(Cos::String)
      dict[Cos::Name.new("key2")].should be_a(Cos::String)
    end

    describe "wrapper" do
      it "wraps a dictionary and syncs entries" do
        dict = Cos::Dictionary.new
        actuals = {} of String => WrapperTestCOSObjectable
        wrapper = COSDictionaryMap(WrapperTestCOSObjectable).new(actuals, dict)
        wrapper.size.should eq 0
        wrapper.empty?.should be_true

        obj = WrapperTestCOSObjectable.new("test")
        wrapper["key"] = obj
        wrapper.size.should eq 1
        dict[Cos::Name.new("key")].should be_a(Cos::String)
        actuals["key"].should eq obj
      end

      it "deletes entry" do
        dict = Cos::Dictionary.new
        dict[Cos::Name.new("key")] = Cos::String.new("value")
        obj = WrapperTestCOSObjectable.new("value")
        actuals = {"key" => obj}
        wrapper = COSDictionaryMap(WrapperTestCOSObjectable).new(actuals, dict)
        wrapper.delete("key").should eq obj
        dict.has_key?(Cos::Name.new("key")).should be_false
        actuals.has_key?("key").should be_false
      end

      it "clears all entries" do
        dict = Cos::Dictionary.new
        dict[Cos::Name.new("key")] = Cos::String.new("value")
        obj = WrapperTestCOSObjectable.new("value")
        actuals = {"key" => obj}
        wrapper = COSDictionaryMap(WrapperTestCOSObjectable).new(actuals, dict)
        wrapper.clear
        wrapper.size.should eq 0
        dict.size.should eq 0
        actuals.size.should eq 0
      end
    end
  end
end
