require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    describe XMPSchema do
      parent = XMPMetadata.create_xmp_metadata
      schem = XMPSchema.new(parent, "nsURI", "nsSchem")

      describe "#test_bag_management" do
        it "manages bag values" do
          bag_name = "BAGTEST"
          value1 = "valueOne"
          value2 = "valueTwo"

          tm = schem.metadata.type_mapping
          li1 = tm.create_text(nil, "rdf", "li", value1)
          schem.add_bag_value(bag_name, li1)
          schem.add_qualified_bag_value(bag_name, value2)

          values = schem.unqualified_bag_value_list(bag_name)
          values.should_not be_nil
          values.not_nil![0].should eq(value1)
          values.not_nil![1].should eq(value2)

          schem.remove_unqualified_bag_value(bag_name, value1)
          values2 = schem.unqualified_bag_value_list(bag_name)
          values2.should_not be_nil
          values2.not_nil!.size.should eq(1)
          values2.not_nil![0].should eq(value2)
        end
      end

      describe "#test_about" do
        it "gets and sets about value" do
          schem.about_value.should eq("")
          about = "about"
          schem.set_about_as_simple(about)
          schem.about_value.should eq(about)
          schem.set_about_as_simple("")
          schem.about_value.should eq("")
          schem.set_about_as_simple(nil)
          schem.about_value.should eq("")
        end
      end

      describe "#test_properties" do
        it "manages core properties" do
          schem.namespace.should eq("nsURI")

          schem.add_namespace("http://www.w3.org/1999/02/22-rdf-syntax-ns#", "rdf")

          about_val = "aboutTest"
          schem.set_about_as_simple(about_val)
          schem.about_value.should eq(about_val)

          attr = Type::Attribute.new(XmpConstants::RDF_NAMESPACE, "about", "YEP")
          schem.about = attr
          schem.about_attribute.try(&.value).should eq("YEP")

          text_prop = "textProp"
          text_prop_val = "TextPropTest"
          schem.set_text_property_value(text_prop, text_prop_val)
          schem.unqualified_text_property_value(text_prop).should eq(text_prop_val)

          text = parent.type_mapping.create_text(nil, "nsSchem", "textType", "GRINGO")
          schem.text_property = text
          schem.unqualified_text_property("textType").should eq(text)

          date_val = Time.utc
          datestr = "nsSchem:dateProp"
          schem.set_date_property_value(datestr, date_val)
          dt = schem.date_property_value(datestr)
          dt.should_not be_nil
          dt.not_nil!.to_unix.should eq(date_val.to_unix)

          date_type = parent.type_mapping.create_date(nil, "nsSchem", "dateType", Time.utc)
          schem.date_property = date_type
          schem.date_property("dateType").should eq(date_type)

          bool_val = false
          schem.set_boolean_property_value("nsSchem:booleanTestProp", bool_val)
          schem.boolean_property_value("nsSchem:booleanTestProp").should eq(bool_val)

          bool_type = parent.type_mapping.create_boolean(nil, "nsSchem", "boolType", false)
          schem.boolean_property = bool_type
          schem.boolean_property("boolType").should eq(bool_type)

          int_val = 5
          schem.set_integer_property_value("nsSchem:IntegerTestProp", int_val)
          schem.integer_property_value("nsSchem:IntegerTestProp").should eq(int_val)

          int_type = parent.type_mapping.create_integer(nil, "nsSchem", "intType", 5)
          schem.integer_property = int_type
          schem.integer_property("intType").should eq(int_type)

          expect_raises(Type::BadFieldValueException) do
            schem.integer_property("boolType")
          end
          expect_raises(Type::BadFieldValueException) do
            schem.date_property("textType")
          end
          expect_raises(Type::BadFieldValueException) do
            schem.boolean_property("dateType")
          end
        end
      end

      describe "#test_alt_properties" do
        it "manages language alternatives" do
          alt_prop = "AltProp"
          default_lang = "x-default"
          default_val = "Default Language"
          us_lang = "en-us"
          us_val = "American Language"
          fr_lang = "fr-fr"
          fr_val = "Lang française"

          schem.set_unqualified_language_property_value(alt_prop, us_lang, us_val)
          schem.set_unqualified_language_property_value(alt_prop, default_lang, default_val)
          schem.set_unqualified_language_property_value(alt_prop, fr_lang, fr_val)

          schem.unqualified_language_property_value(alt_prop, default_lang).should eq(default_val)
          schem.unqualified_language_property_value(alt_prop, fr_lang).should eq(fr_val)
          schem.unqualified_language_property_value(alt_prop, us_lang).should eq(us_val)

          languages = schem.unqualified_language_property_languages_value(alt_prop)
          languages.should_not be_nil
          languages.not_nil![0].should eq(default_lang)
          languages.not_nil!.includes?(us_lang).should be_true
          languages.not_nil!.includes?(fr_lang).should be_true

          # Test replacement/removal
          fr_val2 = "Langue française"
          schem.set_unqualified_language_property_value(alt_prop, fr_lang, fr_val2)
          schem.unqualified_language_property_value(alt_prop, fr_lang).should eq(fr_val2)

          schem.set_unqualified_language_property_value(alt_prop, fr_lang, nil)
          languages2 = schem.unqualified_language_property_languages_value(alt_prop)
          languages2.should_not be_nil
          languages2.not_nil!.includes?(fr_lang).should be_false
          schem.set_unqualified_language_property_value(alt_prop, fr_lang, fr_val)
        end
      end

      describe "#test_merge_schema" do
        it "merges two schemas" do
          bag_name = "bagName"
          seq_name = "seqName"
          alt_name = "AltProp"

          val_bag_schem1 = "BagvalSchem1"
          val_bag_schem2 = "BagvalSchem2"
          val_seq_schem1 = "seqvalSchem1"
          val_seq_schem2 = "seqvalSchem2"
          val_alt_schem1 = "altvalSchem1"
          lang_alt_schem1 = "x-default"
          val_alt_schem2 = "altvalSchem2"
          lang_alt_schem2 = "fr-fr"

          schem1 = XMPSchema.new(parent, "http://www.test.org/schem/", "test")
          schem1.add_qualified_bag_value(bag_name, val_bag_schem1)
          schem1.add_unqualified_sequence_value(seq_name, val_seq_schem1)
          schem1.set_unqualified_language_property_value(alt_name, lang_alt_schem1, val_alt_schem1)

          schem2 = XMPSchema.new(parent, "http://www.test.org/schem/", "test")
          schem2.add_qualified_bag_value(bag_name, val_bag_schem2)
          schem2.add_unqualified_sequence_value(seq_name, val_seq_schem2)
          schem2.set_unqualified_language_property_value(alt_name, lang_alt_schem2, val_alt_schem2)

          schem1.merge(schem2)

          schem1.unqualified_language_property_value(alt_name, lang_alt_schem2).should eq(val_alt_schem2)
          schem1.unqualified_language_property_value(alt_name, lang_alt_schem1).should eq(val_alt_schem1)

          bag = schem1.unqualified_bag_value_list(bag_name)
          bag.should_not be_nil
          bag.not_nil!.includes?(val_bag_schem1).should be_true
          bag.not_nil!.includes?(val_bag_schem2).should be_true

          seq = schem1.unqualified_sequence_value_list(seq_name)
          seq.should_not be_nil
          seq.not_nil!.includes?(val_seq_schem1).should be_true
          seq.not_nil!.includes?(val_seq_schem2).should be_true
        end
      end
    end
  end
end
