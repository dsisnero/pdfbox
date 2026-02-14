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

def get_recipient(certificate_file : String, permission : Pdfbox::Pdmodel::Encryption::AccessPermission)
  # TODO: Implement
  nil
end

KEY_LENGTHS = [40, 128, 256]

describe Pdfbox::Pdmodel::Encryption do
  test_results_dir = "target/test-output/crypto"

  before_all do
    Dir.mkdir_p(test_results_dir)
    # Skip JCE unlimited strength check - not applicable to Crystal
  end

  KEY_LENGTHS.each do |key_length|
    describe "with key length #{key_length}" do
      it "testProtection" do
        # TODO: Implement
      end

      it "testProtectionError" do
        # TODO: Implement
      end

      it "testMultipleRecipients" do
        # TODO: Implement
      end
    end
  end

  it "testReadPubkeyEncryptedAES128" do
    # TODO: Implement
  end

  it "testReadPubkeyEncryptedAES256" do
    # TODO: Implement
  end

  it "testReadPubkeyEncryptedAES128withMetadataExposed" do
    # TODO: Implement
  end

  it "testReadPubkeyEncryptedAES256withMetadataExposed" do
    # TODO: Implement
  end
end
