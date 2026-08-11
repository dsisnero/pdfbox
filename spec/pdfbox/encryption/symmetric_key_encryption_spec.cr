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

require "../../spec_helper"

def get_file_resource_as_byte_array(filename : String) : Bytes
  File.read("spec/resources/pdfbox/encryption/#{filename}").to_slice
end

def check_perms(input_file_as_byte_array : Bytes, password : String,
                expected_permissions : Pdfbox::Pdmodel::Encryption::AccessPermission?) : Nil
  doc = Pdfbox::Loader.load_pdf(input_file_as_byte_array, password)
  current_access_permission = doc.current_access_permission

  # check permissions
  if expected_permissions
    current_access_permission.owner_permission?.should eq expected_permissions.owner_permission?
    unless expected_permissions.owner_permission?
      current_access_permission.read_only?.should be_true
    end
    current_access_permission.can_assemble_document?.should eq expected_permissions.can_assemble_document?
    current_access_permission.can_extract_content?.should eq expected_permissions.can_extract_content?
    current_access_permission.can_extract_for_accessibility?.should eq expected_permissions.can_extract_for_accessibility?
    current_access_permission.can_fill_in_form?.should eq expected_permissions.can_fill_in_form?
    current_access_permission.can_modify?.should eq expected_permissions.can_modify?
    current_access_permission.can_modify_annotations?.should eq expected_permissions.can_modify_annotations?
    current_access_permission.can_print?.should eq expected_permissions.can_print?
    current_access_permission.can_print_faithful?.should eq expected_permissions.can_print_faithful?
  else
    # If expected_permissions is nil, we expect an exception to have been raised earlier
    # This method should not be called with nil expected_permissions
    raise "Expected permissions cannot be nil"
  end
end

def test_symm_encr_for_key_size(filename : String, key_length : Int32, prefer_aes : Bool,
                                size_prior_to_encryption : Int32, input_file_as_byte_array : Bytes,
                                user_password : String, owner_password : String,
                                permission : Pdfbox::Pdmodel::Encryption::AccessPermission) : Nil
  test_results_dir = "target/test-output/crypto"
  document = Pdfbox::Loader.load_pdf(input_file_as_byte_array)
  num_src_pages = document.pages.size

  src_content_streams = [] of Bytes
  document.pages.each do |page|
    stream = page.contents
    src_content_streams << (stream ? stream.create_input_stream.getb_to_end : Bytes.new(0))
  end

  spp = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new(owner_password, user_password, permission)
  spp.encryption_key_length = key_length
  spp.prefer_aes = prefer_aes

  document.protect(spp)
  prefix = "#{filename}-Simple-"
  encrypted_path = File.join(test_results_dir, "#{prefix}#{key_length}-bit-#{prefer_aes ? "AES" : "RC4"}-encrypted.pdf")
  document.save(encrypted_path)
  document.close

  size_encrypted = File.size(encrypted_path)
  size_encrypted.should_not eq(size_prior_to_encryption)

  encrypted_doc = Pdfbox::Loader.load_pdf(encrypted_path, owner_password)
  begin
    encrypted_doc.encrypted?.should be_true
    encrypted_doc.current_access_permission.owner_permission?.should be_true

    encrypted_doc.pages.size.should eq(num_src_pages)
    encrypted_doc.pages.each_with_index do |page, i|
      stream = page.contents
      bytes = stream ? stream.create_input_stream.getb_to_end : Bytes.new(0)
      bytes.should eq(src_content_streams[i])
    end
  ensure
    encrypted_doc.close
  end
end

def extract_embedded_file(input_file_as_byte_array : Bytes, name : String) : Bytes
  doc = Pdfbox::Loader.load_pdf(input_file_as_byte_array).not_nil!
  begin
    catalog = doc.document_catalog.not_nil!
    names = catalog.names.not_nil!
    embedded_files = names.embedded_files.not_nil!
    embedded_file_names = embedded_files.names.not_nil!
    embedded_file_names.size.should eq(1)
    entry = embedded_file_names.first
    puts "Processing embedded file #{entry[0]}:"
    complex_file_spec = entry[1]
    embedded_file = complex_file_spec.embedded_file.not_nil!

    bytes = embedded_file.create_input_stream.not_nil!.getb_to_end
    embedded_file.size.should eq(bytes.size)

    bytes
  ensure
    doc.close
  end
end

def test_symm_encr_for_key_size_inner(key_length : Int32, prefer_aes : Bool,
                                      size_prior_to_encryption : Int32,
                                      input_file_with_embedded_file_as_byte_array : Bytes,
                                      embedded_file_prior_to_encryption : Bytes,
                                      user_password : String, owner_password : String,
                                      permission : Pdfbox::Pdmodel::Encryption::AccessPermission) : Nil
  test_results_dir = "target/test-output/crypto"
  document = Pdfbox::Loader.load_pdf(input_file_with_embedded_file_as_byte_array)

  spp = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new(owner_password, user_password, permission)
  spp.encryption_key_length = key_length
  spp.prefer_aes = prefer_aes

  # This must have no effect and should only log a warning.
  document.set_all_security_to_be_removed(true)

  document.protect(spp)

  prefix = "ContainsEmbedded-"
  encrypted_path = File.join(test_results_dir, "#{prefix}#{key_length}-bit-#{prefer_aes ? "AES" : "RC4"}-encrypted.pdf")
  document.save(encrypted_path)
  document.close

  size_encrypted = File.size(encrypted_path)
  size_encrypted.should_not eq(size_prior_to_encryption)

  encrypted_doc = Pdfbox::Loader.load_pdf(encrypted_path, owner_password)
  begin
    encrypted_doc.encrypted?.should be_true
    encrypted_doc.current_access_permission.owner_permission?.should be_true

    encrypted_doc.set_all_security_to_be_removed(true)
    decrypted_path = File.join(test_results_dir, "DecryptedContainsEmbedded-#{key_length}-bit-#{prefer_aes ? "AES" : "RC4"}.pdf")
    encrypted_doc.save(decrypted_path)

    extracted_embedded_file = extract_embedded_file(File.read(decrypted_path).to_slice,
      "decryptedInnerFile-#{key_length}-bit-#{prefer_aes ? "AES" : "RC4"}.pdf")

    extracted_embedded_file.size.should eq(embedded_file_prior_to_encryption.size)
    extracted_embedded_file.should eq(embedded_file_prior_to_encryption)
  ensure
    encrypted_doc.close
  end
end

USERPASSWORD  = "1234567890abcdefghijk1234567890abcdefghijk"
OWNERPASSWORD = "abcdefghijk1234567890abcdefghijk1234567890"

describe Pdfbox::Pdmodel::Encryption do
  test_results_dir = "target/test-output/crypto"

  permission = uninitialized Pdfbox::Pdmodel::Encryption::AccessPermission

  before_all do
    Dir.mkdir_p(test_results_dir)

    # Skip JCE unlimited strength check - not applicable to Crystal

    permission = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    permission.can_assemble_document = false
    permission.can_extract_content = false
    permission.can_extract_for_accessibility = true
    permission.can_fill_in_form = false
    permission.can_modify = false
    permission.can_modify_annotations = false
    permission.can_print = true
    permission.can_print_faithful = false
    permission.set_read_only
  end

  it "testPermissions" do
    full_ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    restr_ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    restr_ap.can_print = false
    restr_ap.can_extract_content = false
    restr_ap.can_modify = false

    input_file_as_byte_array = get_file_resource_as_byte_array("PasswordSample-40bit.pdf")
    check_perms(input_file_as_byte_array, "owner", full_ap)
    check_perms(input_file_as_byte_array, "user", restr_ap)
    expect_raises(Exception, "Cannot decrypt PDF, the password is incorrect") do
      check_perms(input_file_as_byte_array, "", nil)
    end

    restr_ap.can_assemble_document = false
    restr_ap.can_extract_for_accessibility = false
    restr_ap.can_print_faithful = false

    input_file_as_byte_array = get_file_resource_as_byte_array("PasswordSample-128bit.pdf")
    check_perms(input_file_as_byte_array, "owner", full_ap)
    check_perms(input_file_as_byte_array, "user", restr_ap)
    expect_raises(Exception, "Cannot decrypt PDF, the password is incorrect") do
      check_perms(input_file_as_byte_array, "", nil)
    end

    input_file_as_byte_array = get_file_resource_as_byte_array("PasswordSample-256bit.pdf")
    check_perms(input_file_as_byte_array, "owner", full_ap)
    check_perms(input_file_as_byte_array, "user", restr_ap)
    expect_raises(Exception, "Cannot decrypt PDF, the password is incorrect") do
      check_perms(input_file_as_byte_array, "", nil)
    end
  end

  it "testProtection" do
    filename = "Acroform-PDFBOX-2333.pdf"
    input_file_as_byte_array = get_file_resource_as_byte_array(filename)
    size_prior_to_encryption = input_file_as_byte_array.size

    test_symm_encr_for_key_size(filename, 40, false, size_prior_to_encryption, input_file_as_byte_array,
      USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size(filename, 128, false, size_prior_to_encryption, input_file_as_byte_array,
      USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size(filename, 128, true, size_prior_to_encryption, input_file_as_byte_array,
      USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size(filename, 256, true, size_prior_to_encryption, input_file_as_byte_array,
      USERPASSWORD, OWNERPASSWORD, permission)
  end

  it "testPDFBox4308" do
  end

  it "testPDFBox5955" do
  end

  it "testProtectionInnerAttachment" do
    test_file_name = "preEnc_20141025_105451.pdf"
    input_file_with_embedded_file_as_byte_array = get_file_resource_as_byte_array(test_file_name)
    size_of_file_with_embedded_file = input_file_with_embedded_file_as_byte_array.size

    extracted_embedded_file = extract_embedded_file(input_file_with_embedded_file_as_byte_array, "innerFile.pdf")

    test_symm_encr_for_key_size_inner(40, false, size_of_file_with_embedded_file,
      input_file_with_embedded_file_as_byte_array, extracted_embedded_file, USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size_inner(128, false, size_of_file_with_embedded_file,
      input_file_with_embedded_file_as_byte_array, extracted_embedded_file, USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size_inner(128, true, size_of_file_with_embedded_file,
      input_file_with_embedded_file_as_byte_array, extracted_embedded_file, USERPASSWORD, OWNERPASSWORD, permission)

    test_symm_encr_for_key_size_inner(256, true, size_of_file_with_embedded_file,
      input_file_with_embedded_file_as_byte_array, extracted_embedded_file, USERPASSWORD, OWNERPASSWORD, permission)
  end

  it "testPDFBox4453" do
    # PDFBOX-4453: verify that identical encrypted strings are really decrypted each.
    testcount = 1000
    file = File.join(test_results_dir, "PDFBOX-4453.pdf")
    doc = Pdfbox::Pdmodel::Document.create
    begin
      doc.add_page(Pdfbox::Pdmodel::Page.new)
      testcount.times do |i|
        # strings must be in different dictionaries so that the actual
        # encryption key changes
        dict = Pdfbox::Cos::Dictionary.new
        doc.pages[0].cos_object.not_nil![Pdfbox::Cos::Name.new("_Test-#{i}")] = dict
        # need two different keys so that there are both encrypted and decrypted COSStrings
        # with value "0"
        dict.set_string("key1", "3")
        dict.set_string("key2", "0")
      end

      # RC4-40
      spp = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new("12345", "",
        Pdfbox::Pdmodel::Encryption::AccessPermission.new)
      spp.encryption_key_length = 40
      spp.prefer_aes = false
      doc.protect(spp)
      doc.save(file)
    ensure
      doc.close
    end

    reopened = Pdfbox::Loader.load_pdf(file)
    begin
      reopened.encrypted?.should be_true
      testcount.times do |i|
        dict_value = reopened.pages[0].cos_object.not_nil![Pdfbox::Cos::Name.new("_Test-#{i}")]
        dict_value = dict_value.object if dict_value.is_a?(Pdfbox::Cos::Object)
        dict = dict_value.as(Pdfbox::Cos::Dictionary)
        dict.get_string(Pdfbox::Cos::Name.new("key1")).should eq("3")
        dict.get_string(Pdfbox::Cos::Name.new("key2")).should eq("0")
      end
    ensure
      reopened.close
    end
  end

  it "testPDFBox5639" do
  end
end
