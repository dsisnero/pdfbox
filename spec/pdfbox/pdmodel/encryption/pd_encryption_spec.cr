# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "../../../spec_helper"

describe Pdfbox::Pdmodel::Encryption::PDEncryption do
  describe "#permissions" do
    it "returns permissions from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("P")] = Pdfbox::Cos::Integer.new(-4_i64)
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.permissions.should eq(-4)
    end

    it "returns 0 when P entry missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.permissions.should eq(0)
    end

    it "returns 0 when P entry is not an integer" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("P")] = Pdfbox::Cos::String.new("not an integer")
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.permissions.should eq(0)
    end
  end

  describe "#permissions=" do
    it "sets permissions in dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.permissions = -4
      encryption.permissions.should eq(-4)
    end
  end

  describe "#filter" do
    it "returns filter from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Filter")] = Pdfbox::Cos::Name.new("Standard")
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.filter.should eq("Standard")
    end

    it "returns default when Filter missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.filter.should eq("Standard")
    end
  end

  describe "#version" do
    it "returns version from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("V")] = Pdfbox::Cos::Integer.new(2_i64)
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.version.should eq(2)
    end

    it "returns 0 when V missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.version.should eq(0)
    end
  end

  describe "#revision" do
    it "returns revision from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("R")] = Pdfbox::Cos::Integer.new(3_i64)
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.revision.should eq(3)
    end

    it "returns default when R missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.revision.should eq(Pdfbox::Pdmodel::Encryption::PDEncryption::DEFAULT_VERSION)
    end

    it "sets revision in dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.revision = 5
      encryption.revision.should eq(5)
    end
  end

  describe "#length" do
    it "returns length from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("Length")] = Pdfbox::Cos::Integer.new(128_i64)
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.length.should eq(128)
    end

    it "returns default when Length missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.length.should eq(Pdfbox::Pdmodel::Encryption::PDEncryption::DEFAULT_LENGTH)
    end

    it "sets length in dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.length = 256
      encryption.length.should eq(256)
    end
  end

  describe "#owner_key" do
    it "returns owner key bytes from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("O")] = Pdfbox::Cos::String.new(Bytes[1, 2, 3, 4])
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      bytes = encryption.owner_key
      bytes.should_not be_nil
      bytes.not_nil!.size.should eq(32) # default revision <= 4
      bytes.not_nil![0, 4].should eq(Bytes[1, 2, 3, 4])
    end

    it "returns nil when O entry missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.owner_key.should be_nil
    end

    it "pads to 48 bytes for revision 5" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("R")] = Pdfbox::Cos::Integer.new(5_i64)
      dict[Pdfbox::Cos::Name.new("O")] = Pdfbox::Cos::String.new(Bytes[5, 6, 7, 8])
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      bytes = encryption.owner_key
      bytes.should_not be_nil
      bytes.not_nil!.size.should eq(48)
      bytes.not_nil![0, 4].should eq(Bytes[5, 6, 7, 8])
    end
  end

  describe "#user_key" do
    it "returns user key bytes from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("U")] = Pdfbox::Cos::String.new(Bytes[10, 11, 12])
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      bytes = encryption.user_key
      bytes.should_not be_nil
      bytes.not_nil!.size.should eq(32)
      bytes.not_nil![0, 3].should eq(Bytes[10, 11, 12])
    end

    it "returns nil when U entry missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.user_key.should be_nil
    end
  end

  describe "#owner_encryption_key" do
    it "returns OE bytes from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("OE")] = Pdfbox::Cos::String.new(Bytes[20, 21, 22])
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      bytes = encryption.owner_encryption_key
      bytes.should_not be_nil
      bytes.not_nil!.size.should eq(32)
      bytes.not_nil![0, 3].should eq(Bytes[20, 21, 22])
    end

    it "returns nil when OE entry missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.owner_encryption_key.should be_nil
    end
  end

  describe "#user_encryption_key" do
    it "returns UE bytes from dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      dict[Pdfbox::Cos::Name.new("UE")] = Pdfbox::Cos::String.new(Bytes[30, 31, 32])
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      bytes = encryption.user_encryption_key
      bytes.should_not be_nil
      bytes.not_nil!.size.should eq(32)
      bytes.not_nil![0, 3].should eq(Bytes[30, 31, 32])
    end

    it "returns nil when UE entry missing" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.user_encryption_key.should be_nil
    end

    it "sets version in dictionary" do
      dict = Pdfbox::Cos::Dictionary.new
      encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
      encryption.version = 3
      encryption.version.should eq(3)
    end
  end

  it "sets filter in dictionary" do
    dict = Pdfbox::Cos::Dictionary.new
    encryption = Pdfbox::Pdmodel::Encryption::PDEncryption.new(dict)
    encryption.filter = "CustomFilter"
    encryption.filter.should eq("CustomFilter")
  end
end
