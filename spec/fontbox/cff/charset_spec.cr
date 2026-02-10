require "../../spec_helper"

module Fontbox::CFF
  describe Charset do
    it "test_embedded_charset" do
      # true -> CharsetCID
      embedded_charset_cid = EmbeddedCharset.new(true)
      embedded_charset_cid.is_cid_font?.should be_true
      embedded_charset_cid.add_cid(10, 20)
      # test existing mapping
      embedded_charset_cid.get_gid_for_cid(20).should eq 10
      embedded_charset_cid.get_cid_for_gid(10).should eq 20
      # test not existing mapping
      embedded_charset_cid.get_gid_for_cid(99).should eq 0
      embedded_charset_cid.get_cid_for_gid(99).should eq 0
      # test not allowed method calls
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        embedded_charset_cid.get_sid_for_gid(0)
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        embedded_charset_cid.get_gid_for_sid(0)
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        embedded_charset_cid.add_sid(0, 0, "test")
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        embedded_charset_cid.get_sid("test")
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        embedded_charset_cid.get_name_for_gid(0)
      end
      # false -> CharsetType1
      embedded_charset_type1 = EmbeddedCharset.new(false)
      embedded_charset_type1.is_cid_font?.should be_false
      embedded_charset_type1.add_sid(10, 20, "test")
      # test existing mapping
      embedded_charset_type1.get_sid("test").should eq 20
      embedded_charset_type1.get_gid_for_sid(20).should eq 10
      embedded_charset_type1.get_sid_for_gid(10).should eq 20
      # test not existing mapping
      embedded_charset_type1.get_gid_for_sid(99).should eq 0
      embedded_charset_type1.get_sid_for_gid(99).should eq 0
      # test not allowed method calls
      expect_raises(Exception, "Not a CIDFont") do
        embedded_charset_type1.get_cid_for_gid(0)
      end
      expect_raises(Exception, "Not a CIDFont") do
        embedded_charset_type1.get_gid_for_cid(0)
      end
      expect_raises(Exception, "Not a CIDFont") do
        embedded_charset_type1.add_cid(0, 0)
      end
    end

    it "test_charset_cid" do
      charset_cid = CharsetCID.new
      charset_cid.is_cid_font?.should be_true
      charset_cid.add_cid(10, 20)
      # test existing mapping
      charset_cid.get_gid_for_cid(20).should eq 10
      charset_cid.get_cid_for_gid(10).should eq 20
      # test not existing mapping
      charset_cid.get_gid_for_cid(99).should eq 0
      charset_cid.get_cid_for_gid(99).should eq 0
      # test not allowed method calls
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        charset_cid.get_sid_for_gid(0)
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        charset_cid.get_gid_for_sid(0)
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        charset_cid.add_sid(0, 0, "test")
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        charset_cid.get_sid("test")
      end
      expect_raises(Exception, "Not a Type 1-equivalent font") do
        charset_cid.get_name_for_gid(0)
      end
    end

    it "test_charset_type1" do
      charset_type1 = CharsetType1.new
      charset_type1.is_cid_font?.should be_false
      charset_type1.add_sid(10, 20, "test")
      # test existing mapping
      charset_type1.get_sid("test").should eq 20
      charset_type1.get_gid_for_sid(20).should eq 10
      charset_type1.get_sid_for_gid(10).should eq 20
      # test not existing mapping
      charset_type1.get_gid_for_sid(99).should eq 0
      charset_type1.get_sid_for_gid(99).should eq 0
      # test not allowed method calls
      expect_raises(Exception, "Not a CIDFont") do
        charset_type1.get_cid_for_gid(0)
      end
      expect_raises(Exception, "Not a CIDFont") do
        charset_type1.get_gid_for_cid(0)
      end
      expect_raises(Exception, "Not a CIDFont") do
        charset_type1.add_cid(0, 0)
      end
    end

    it "test_expert_charset" do
      expert_charset = ExpertCharset.instance
      # check .notdef mapping
      expert_charset.get_sid_for_gid(0).should eq 0
      expert_charset.get_sid(".notdef").should eq 0
      expert_charset.get_name_for_gid(0).should eq ".notdef"
      # check some randomly chosen mappings
      expert_charset.get_sid_for_gid(32).should eq 253
      expert_charset.get_sid("asuperior").should eq 253
      expert_charset.get_name_for_gid(32).should eq "asuperior"

      expert_charset.get_sid_for_gid(17).should eq 240
      expert_charset.get_sid("oneoldstyle").should eq 240
      expert_charset.get_name_for_gid(17).should eq "oneoldstyle"

      expert_charset.get_sid_for_gid(134).should eq 347
      expert_charset.get_sid("Agravesmall").should eq 347
      expert_charset.get_name_for_gid(134).should eq "Agravesmall"
    end

    it "test_expert_subset_charset" do
      expert_subset_charset = ExpertSubsetCharset.instance
      # check .notdef mapping
      expert_subset_charset.get_sid_for_gid(0).should eq 0
      expert_subset_charset.get_sid(".notdef").should eq 0
      expert_subset_charset.get_name_for_gid(0).should eq ".notdef"
      # check some randomly chosen mappings
      expert_subset_charset.get_sid_for_gid(19).should eq 246
      expert_subset_charset.get_sid("sevenoldstyle").should eq 246
      expert_subset_charset.get_name_for_gid(19).should eq "sevenoldstyle"

      expert_subset_charset.get_sid_for_gid(61).should eq 324
      expert_subset_charset.get_sid("onethird").should eq 324
      expert_subset_charset.get_name_for_gid(61).should eq "onethird"

      expert_subset_charset.get_sid_for_gid(85).should eq 345
      expert_subset_charset.get_sid("periodinferior").should eq 345
      expert_subset_charset.get_name_for_gid(85).should eq "periodinferior"
    end

    it "test_iso_adobe_charset" do
      iso_adobe_charset = ISOAdobeCharset.instance
      # check .notdef mapping
      iso_adobe_charset.get_sid_for_gid(0).should eq 0
      iso_adobe_charset.get_sid(".notdef").should eq 0
      iso_adobe_charset.get_name_for_gid(0).should eq ".notdef"

      # check some randomly chosen mappings
      iso_adobe_charset.get_sid_for_gid(32).should eq 32
      iso_adobe_charset.get_sid("question").should eq 32
      iso_adobe_charset.get_name_for_gid(32).should eq "question"

      iso_adobe_charset.get_sid_for_gid(76).should eq 76
      iso_adobe_charset.get_sid("k").should eq 76
      iso_adobe_charset.get_name_for_gid(76).should eq "k"

      iso_adobe_charset.get_sid_for_gid(218).should eq 218
      iso_adobe_charset.get_sid("odieresis").should eq 218
      iso_adobe_charset.get_name_for_gid(218).should eq "odieresis"
    end
  end
end
