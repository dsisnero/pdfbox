require "./pd_prop_build"

# A digital signature that can be attached to a document.
#
# Ported from Apache PDFBox PDSignature (focus: byte range and contents).
module Pdfbox::Pdmodel::Interactive::Form
  class PDSignature
    FILTER_ADOBE_PPKLITE  = Cos::Name.new("Adobe.PPKLite")
    FILTER_ENTRUST_PPKEF  = Cos::Name.new("Entrust.PPKEF")
    FILTER_CICI_SIGNIT    = Cos::Name.new("CICI.SignIt")
    FILTER_VERISIGN_PPKVS = Cos::Name.new("VeriSign.PPKVS")

    SUBFILTER_ADBE_X509_RSA_SHA1  = Cos::Name.new("adbe.x509.rsa_sha1")
    SUBFILTER_ADBE_PKCS7_DETACHED = Cos::Name.new("adbe.pkcs7.detached")
    SUBFILTER_ADBE_PKCS7_SHA1     = Cos::Name.new("adbe.pkcs7.sha1")
    SUBFILTER_ETSI_CADES_DETACHED = Cos::Name.new("ETSI.CAdES.detached")

    @dictionary : Cos::Dictionary

    # Default constructor.
    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name::TYPE] = Cos::Name.new("Sig")
    end

    # Constructor.
    def initialize(dictionary : Cos::Dictionary)
      @dictionary = dictionary
    end

    # Convert this object to a COS dictionary.
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Sets the byte range. Java PDSignature#setByteRange; a non-4-length range
    # is ignored.
    def byte_range=(range : Array(Int32)) : Nil
      return if range.size != 4

      array = Cos::Array.new
      range.each do |value|
        array.add(Cos::Integer.new(value.to_i64))
      end
      @dictionary[Cos::Name.new("ByteRange")] = array
    end

    # Read out the byterange. Java PDSignature#getByteRange; empty array if none.
    def byte_range : Array(Int32)
      byte_range = @dictionary.get_array(Cos::Name.new("ByteRange"))
      return [] of Int32 if byte_range.nil?

      result = Array(Int32).new(byte_range.size)
      byte_range.size.times do |i|
        item = byte_range.get(i)
        result << case item
        when Cos::Integer then item.value.to_i32
        when Cos::Float   then item.value.to_i32
        else                   0
        end
      end
      result
    end

    # Returns the /Contents string as a byte array. Java PDSignature#getContents.
    def contents : Bytes
      base = @dictionary[Cos::Name.new("Contents")]?
      base = base.object if base.is_a?(Cos::Object)
      if base.is_a?(Cos::String)
        return base.bytes
      end
      Bytes.empty
    end

    # Return the embedded signature between the byterange gap, from a byte array.
    # Java PDSignature#getContents(byte[]).
    def get_contents(pdf_file : Bytes) : Bytes
      byte_range = self.byte_range
      begin_idx = byte_range[0] + byte_range[1] + 1
      len = byte_range[2] - begin_idx - 1

      get_converted_contents(pdf_file[begin_idx, len])
    end

    # Return the embedded signature between the byterange gap, from an IO.
    # Java PDSignature#getContents(InputStream).
    def get_contents(pdf_file : ::IO) : Bytes
      byte_range = self.byte_range
      begin_idx = byte_range[0] + byte_range[1] + 1
      len = byte_range[2] - begin_idx

      pdf_file.seek(begin_idx)
      data = Bytes.new(len)
      pdf_file.read_fully(data)
      get_converted_contents(data)
    end

    private def get_converted_contents(data : Bytes) : Bytes
      start = 0
      write_len = data.size
      # Filter < and (
      if data.size > 0 && (data[0] == 0x3C || data[0] == 0x28)
        start += 1
        write_len -= 1
      end
      # Filter > and ) at the end
      if data.size > 0 && (data[data.size - 1] == 0x3E || data[data.size - 1] == 0x29)
        write_len -= 1
      end

      hex_text = String.new(data[start, write_len])
      Cos::String.parse_hex(hex_text).bytes
    end

    # Java PDSignature#getPropBuild.
    def prop_build : PDPropBuild?
      dictionary = @dictionary.get_dictionary(Cos::Name.new("Prop_Build"))
      dictionary ? PDPropBuild.new(dictionary) : nil
    end

    # Java PDSignature#setPropBuild.
    def prop_build=(prop_build : PDPropBuild?) : Nil
      key = Cos::Name.new("Prop_Build")
      if prop_build
        @dictionary[key] = prop_build.cos_object
      else
        @dictionary.delete(key)
      end
    end

    # Sets the /Type entry (Java setType).
    def type=(type : Cos::Name) : Nil
      @dictionary[Cos::Name::TYPE] = type
    end

    # The signature filter (/Filter), or nil (Java getFilter).
    def filter : String?
      @dictionary.get_name_as_string(Cos::Name::FILTER)
    end

    def filter=(filter : Cos::Name) : Nil
      @dictionary[Cos::Name::FILTER] = filter
    end

    # The signature sub-filter (/SubFilter), or nil (Java getSubFilter).
    def sub_filter : String?
      @dictionary.get_name_as_string(Cos::Name.new("SubFilter"))
    end

    def sub_filter=(sub_filter : Cos::Name) : Nil
      @dictionary[Cos::Name.new("SubFilter")] = sub_filter
    end

    def name : String?
      @dictionary.get_string(Cos::Name::NAME)
    end

    def name=(name : String) : Nil
      @dictionary.set_string(Cos::Name::NAME, name)
    end

    def location : String?
      @dictionary.get_string(Cos::Name.new("Location"))
    end

    def location=(location : String) : Nil
      @dictionary.set_string(Cos::Name.new("Location"), location)
    end

    def reason : String?
      @dictionary.get_string(Cos::Name.new("Reason"))
    end

    def reason=(reason : String) : Nil
      @dictionary.set_string(Cos::Name.new("Reason"), reason)
    end

    def contact_info : String?
      @dictionary.get_string(Cos::Name.new("ContactInfo"))
    end

    def contact_info=(contact_info : String) : Nil
      @dictionary.set_string(Cos::Name.new("ContactInfo"), contact_info)
    end

    # The signing date (/M), or nil (Java getSignDate).
    def sign_date : Time?
      @dictionary.get_date(Cos::Name.new("M"))
    end

    def sign_date=(sign_date : Time) : Nil
      @dictionary.set_date(Cos::Name.new("M"), sign_date)
    end

    # Sets the /Contents entry as raw bytes (Java setContents).
    # ameba:disable Naming/AccessorMethodName
    def set_contents(bytes : Bytes) : Nil
      @dictionary[Cos::Name.new("Contents")] = Cos::String.new(bytes, true)
    end

    # Returns the signed content over the byte range (Java getSignedContent).
    def signed_content(pdf_file : Bytes) : Bytes
      Pdfbox::Pdmodel::Interactive::DigitalSignature::COSFilterInputStream
        .new(pdf_file, byte_range).to_byte_array
    end

    def signed_content(pdf_file : ::IO) : Bytes
      Pdfbox::Pdmodel::Interactive::DigitalSignature::COSFilterInputStream
        .new(pdf_file, byte_range).to_byte_array
    end
  end
end
