# This represents an embedded file in a file specification.
require "../pdstream"

class Pdfbox::Pdmodel::Common::Filespecification::PDEmbeddedFile < ::Pdfbox::Pdmodel::Common::PDStream
  # Constructor wrapping a COSStream
  def initialize(stream : Cos::Stream)
    super(stream)
    cos_object.set_item(Cos::Name::TYPE, Cos::Name::EMBEDDED_FILE)
  end

  # Set the subtype for this embedded file.  This should be a mime type value.  Optional.
  #
  # @param mimeType The mimeType for the file.
  def subtype=(mime_type : String) : Nil
    cos_object.set_name(Cos::Name::SUBTYPE, mime_type)
  end

  # Get the subtype(mimetype) for the embedded file.
  #
  # @return The type of embedded file.
  def subtype : String?
    cos_object[Cos::Name::SUBTYPE].as?(Cos::Name).try(&.value)
  end

  # Get the size of the embedded file.
  #
  # @return The size of the embedded file.
  def size : Int32
    cos_object.get_embedded_int(Cos::Name::PARAMS, Cos::Name::SIZE) || 0
  end

  # Set the size of the embedded file.
  #
  # @param size The size of the embedded file.
  def size=(size_value : Int32) : Nil
    cos_object.set_embedded_int(Cos::Name::PARAMS, Cos::Name::SIZE, size_value)
  end

  # Get the creation date of the embedded file.
  #
  # @return The Creation date.
  def creation_date : Time?
    cos_object.get_embedded_date(Cos::Name::PARAMS, Cos::Name::CREATION_DATE)
  end

  # Set the creation date.
  #
  # @param creation The new creation date.
  def creation_date=(creation : Time) : Nil
    cos_object.set_embedded_date(Cos::Name::PARAMS, Cos::Name::CREATION_DATE, creation)
  end

  # Get the mod date of the embedded file.
  #
  # @return The mod date.
  def mod_date : Time?
    cos_object.get_embedded_date(Cos::Name::PARAMS, Cos::Name::MOD_DATE)
  end

  # Set the mod date.
  #
  # @param mod The new creation mod.
  def mod_date=(mod : Time) : Nil
    cos_object.set_embedded_date(Cos::Name::PARAMS, Cos::Name::MOD_DATE, mod)
  end

  # Get the check sum of the embedded file.
  #
  # @return The check sum of the file.
  def check_sum : String?
    cos_object.get_embedded_string(Cos::Name::PARAMS, Cos::Name::CHECK_SUM)
  end

  # Set the check sum.
  #
  # @param checksum The checksum of the file.
  def check_sum=(checksum : String) : Nil
    cos_object.set_embedded_string(Cos::Name::PARAMS, Cos::Name::CHECK_SUM, checksum)
  end

  # Get the mac subtype.
  #
  # @return The mac subtype.
  def mac_subtype : String?
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    return nil unless params
    params.get_embedded_string(Cos::Name::MAC, Cos::Name::SUBTYPE)
  end

  # Set the mac subtype.
  #
  # @param mac_subtype The mac subtype.
  def mac_subtype=(mac_subtype : String) : Nil
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    if params.nil? && !mac_subtype.empty?
      params = Cos::Dictionary.new
      cos_object.set_item(Cos::Name::PARAMS, params)
    end
    params.try &.set_embedded_string(Cos::Name::MAC, Cos::Name::SUBTYPE, mac_subtype)
  end

  # Get the mac Creator.
  #
  # @return The mac Creator.
  def mac_creator : String?
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    return nil unless params
    params.get_embedded_string(Cos::Name::MAC, Cos::Name::CREATOR)
  end

  # Set the mac Creator.
  #
  # @param mac_creator The mac Creator.
  def mac_creator=(mac_creator : String) : Nil
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    if params.nil? && !mac_creator.empty?
      params = Cos::Dictionary.new
      cos_object.set_item(Cos::Name::PARAMS, params)
    end
    params.try &.set_embedded_string(Cos::Name::MAC, Cos::Name::CREATOR, mac_creator)
  end

  # Get the mac ResFork.
  #
  # @return The mac ResFork.
  def mac_res_fork : String?
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    return nil unless params
    params.get_embedded_string(Cos::Name::MAC, Cos::Name::RES_FORK)
  end

  # Set the mac ResFork.
  #
  # @param mac_res_fork The mac ResFork.
  def mac_res_fork=(mac_res_fork : String) : Nil
    params = cos_object[Cos::Name::PARAMS].as?(Cos::Dictionary)
    if params.nil? && !mac_res_fork.empty?
      params = Cos::Dictionary.new
      cos_object.set_item(Cos::Name::PARAMS, params)
    end
    params.try &.set_embedded_string(Cos::Name::MAC, Cos::Name::RES_FORK, mac_res_fork)
  end
end
