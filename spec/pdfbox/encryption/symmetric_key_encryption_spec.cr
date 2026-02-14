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
  # TODO: Implement
end

def test_symm_encr_for_key_size_inner(key_length : Int32, prefer_aes : Bool,
                                      user_password : String, owner_password : String,
                                      permission : Pdfbox::Pdmodel::Encryption::AccessPermission) : Nil
  # TODO: Implement
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
    permission.set_can_assemble_document(false)
    permission.set_can_extract_content(false)
    permission.set_can_extract_for_accessibility(true)
    permission.set_can_fill_in_form(false)
    permission.set_can_modify(false)
    permission.set_can_modify_annotations(false)
    permission.set_can_print(true)
    permission.set_can_print_faithful(false)
    permission.set_read_only
  end

  it "testPermissions" do
    full_ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    restr_ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    restr_ap.set_can_print(false)
    restr_ap.set_can_extract_content(false)
    restr_ap.set_can_modify(false)

    input_file_as_byte_array = get_file_resource_as_byte_array("PasswordSample-40bit.pdf")
    check_perms(input_file_as_byte_array, "owner", full_ap)
    check_perms(input_file_as_byte_array, "user", restr_ap)
    expect_raises(Exception, "Cannot decrypt PDF, the password is incorrect") do
      check_perms(input_file_as_byte_array, "", nil)
    end

    restr_ap.set_can_assemble_document(false)
    restr_ap.set_can_extract_for_accessibility(false)
    restr_ap.set_can_print_faithful(false)

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
  end

  it "testPDFBox4308" do
  end

  it "testPDFBox5955" do
  end

  it "testProtectionInnerAttachment" do
  end

  it "testPDFBox4453" do
  end

  it "testPDFBox5639" do
  end
end
