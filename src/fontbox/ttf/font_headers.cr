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

module Fontbox::TTF
  # To improve performance of FileSystemFontProvider.scan_fonts(...),
  # this class is used both as a marker (to skip unused data) and as a storage for collected data.
  #
  # Tables it needs:
  # - NamingTable.TAG
  # - HeaderTable.TAG
  # - OS2WindowsMetricsTable.TAG
  # - CFFTable.TAG (for OTF)
  # - "gcid" (for non-OTF)
  #
  # Ported from Apache PDFBox FontHeaders.
  class FontHeaders
    BYTES_GCID = 142

    @error : String?
    @name : String?
    @header_mac_style : Int32?
    @os2_windows : OS2WindowsMetricsTable?
    @font_family : String?
    @font_sub_family : String?
    @non_otf_gcid142 : Bytes?
    @is_otf_and_post_script : Bool = false
    @otf_registry : String?
    @otf_ordering : String?
    @otf_supplement : Int32 = 0

    def get_error : String?
      @error
    end

    def get_name : String?
      @name
    end

    # null == no HeaderTable, ttf.get_header().get_mac_style()
    def get_header_mac_style : Int32?
      @header_mac_style
    end

    # Sets the header mac style.
    def set_header_mac_style(mac_style : Int32) : Nil
      @header_mac_style = mac_style
    end

    def get_os2_windows : OS2WindowsMetricsTable?
      @os2_windows
    end

    # only when LOGGER(FileSystemFontProvider).is_trace_enabled() tracing: FontFamily, FontSubfamily
    def get_font_family : String?
      @font_family
    end

    def get_font_sub_family : String?
      @font_sub_family
    end

    def is_open_type_post_script? : Bool
      @is_otf_and_post_script
    end

    def get_non_otf_table_gcid142 : Bytes?
      @non_otf_gcid142
    end

    def get_otf_registry : String?
      @otf_registry
    end

    def get_otf_ordering : String?
      @otf_ordering
    end

    def get_otf_supplement : Int32
      @otf_supplement
    end

    def set_os2_windows(os2 : OS2WindowsMetricsTable) : Nil
      @os2_windows = os2
    end

    def set_error(error : String) : Nil
      @error = error
    end

    def set_non_otf_gcid142(bytes : Bytes) : Nil
      @non_otf_gcid142 = bytes
    end

    def set_is_otf_and_post_script(value : Bool) : Nil
      @is_otf_and_post_script = value
    end

    def set_name(name : String?) : Nil
      @name = name
    end

    def set_font_family(font_family : String?, font_sub_family : String?) : Nil
      @font_family = font_family
      @font_sub_family = font_sub_family
    end
  end
end
