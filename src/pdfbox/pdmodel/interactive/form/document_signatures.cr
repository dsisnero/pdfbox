module Pdfbox::Pdmodel
  # Signature-related helpers on PDDocument (Java PDDocument#getSignatureFields,
  # getSignatureDictionaries, getLastSignatureDictionary, addSignature,
  # saveIncrementalForExternalSigning).
  class Document
    # The /ByteRange placeholder Java reserves in PDDocument#addSignature; the
    # writer replaces it with the real values (PDF 32000-1 12.8.1).
    RESERVE_BYTE_RANGE = [0, 1_000_000_000, 1_000_000_000, 1_000_000_000]

    @signature_added = false

    # Whether add_signature was already called (only one signature per PDDocument
    # may be prepared; sign again by reloading the saved file).
    def signature_added? : Bool
      @signature_added
    end

    # Prepares the document for a signature (Java PDDocument#addSignature(sig,
    # null, options)): reserves the /Contents placeholder and the /ByteRange, then
    # creates the signature field, its widget and the AcroForm wiring.
    #
    # The signature interface overload of Java is not ported (there is no
    # SignatureInterface / CMS implementation); use
    # #save_incremental_for_external_signing.
    def add_signature(sig_object : Interactive::Form::PDSignature,
                      options : Interactive::DigitalSignature::SignatureOptions = Interactive::DigitalSignature::SignatureOptions.new) : Nil
      if @signature_added
        raise IllegalStateError.new("Only one signature may be added in a document")
      end
      @signature_added = true

      # Reserve the contents: a CMS signature with its certificate chain can be
      # large, so space is reserved up front.
      preferred = options.preferred_signature_size
      size = preferred.positive? ? preferred : Interactive::DigitalSignature::SignatureOptions::DEFAULT_SIGNATURE_SIZE
      sig_object.set_contents(Bytes.new(size))
      sig_object.byte_range = RESERVE_BYTE_RANGE

      pages_list = pages
      if pages_list.empty?
        raise IllegalStateError.new("Cannot sign an empty document")
      end

      catalog = document_catalog
      raise IllegalStateError.new("Cannot sign a document without a document catalog") unless catalog

      acro_form = catalog.acro_form(nil)
      catalog.cos_object.set_need_to_be_updated(true)
      if acro_form
        acro_form.cos_object.set_need_to_be_updated(true)
      else
        acro_form = Interactive::Form::PDAcroForm.new(self)
        catalog.acro_form = acro_form
      end

      signature_field = nil.as(Interactive::Form::PDSignatureField?)
      fields_name = Cos::Name.new("Fields")
      field_array = acro_form.cos_object[fields_name]
      if field_array.is_a?(Cos::Array)
        field_array.set_need_to_be_updated(true)
        signature_field = find_signature_field(acro_form.get_field_tree, sig_object)
      else
        acro_form.cos_object[fields_name] = Cos::Array.new
      end

      page = nil.as(Page?)
      if signature_field
        widget = signature_field.widgets.first
        sig_object.cos_object.set_need_to_be_updated(true)
      else
        signature_field = Interactive::Form::PDSignatureField.new(acro_form)
        signature_field.set_value(sig_object)
        widget = signature_field.widgets.first
        start_index = Math.min(Math.max(options.page, 0), pages_list.size - 1)
        page = pages_list[start_index]
        widget.page = page
      end

      # PDF/A-1: the widget's Print flag must be set, Hidden/Invisible/NoView
      # cleared.
      widget.printed = true

      # Set the AcroForm fields.
      acro_form.cos_object.direct = true
      acro_form.signatures_exist = true
      acro_form.append_only = true

      if check_signature_field(acro_form.get_field_tree, signature_field)
        signature_field.cos_object.set_need_to_be_updated(true)
      else
        # PDAcroForm#fields rebuilds the list, so the field is added to /Fields
        # directly (Java acroFormFields.add(signatureField)).
        acro_form.add_field(signature_field)
      end

      if visual_signature = options.visual_signature
        prepare_visible_signature(widget, acro_form, visual_signature)
      else
        prepare_non_visible_signature(widget)
      end

      if page
        # Appending the widget to the page's /Annots; assigning the array back
        # makes it a direct object (Java does the same to keep an existing
        # indirect /Annots from being dropped by an incremental save).
        annotations = page.annotations
        if check_signature_annotation(annotations.to_a, widget)
          widget.cos_object.set_need_to_be_updated(true)
        else
          annotations.add(widget)
        end
        page.annotations = annotations
        page.cos_object.try(&.set_need_to_be_updated(true))
      end
    end

    # Saves the PDF incrementally without closing it, for external signature
    # creation (Java PDDocument#saveIncrementalForExternalSigning): add the
    # signature with #add_signature, take the data to sign from the returned
    # ExternalSigningSupport, create the CMS signature elsewhere, then store it
    # with ExternalSigningSupport#set_signature.
    def save_incremental_for_external_signing(io : ::IO) : Interactive::DigitalSignature::SigningSupport
      subset_embedded_fonts
      raise IllegalStateError.new("document was not loaded from a file or a stream") if source_bytes.nil?

      # PDFBOX-3978: getLastSignatureDictionary() is not helpful when signing a
      # template that is not the last signature, so the signature with the update
      # flag has priority.
      found_signature = nil.as(Interactive::Form::PDSignature?)
      signature_dictionaries.each do |signature|
        found_signature = signature
        break if signature.cos_object.need_to_be_updated?
      end

      unless found_signature
        raise IllegalStateError.new("document does not contain signature fields")
      end

      unless found_signature.byte_range == RESERVE_BYTE_RANGE
        raise IllegalStateError.new(
          "signature reserve byte range has been changed after addSignature(), " \
          "please set the byte range that existed after addSignature()"
        )
      end

      writer = Pdfwriter::Writer.new(io, self,
        Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
      writer.write_incremental_for_external_signing
    end

    # The signature field that already holds *sig_object* (Java findSignatureField).
    private def find_signature_field(fields : Enumerable(Interactive::Form::PDField),
                                     sig_object : Interactive::Form::PDSignature) : Interactive::Form::PDSignatureField?
      fields.each do |field|
        next unless field.is_a?(Interactive::Form::PDSignatureField)
        signature = field.signature
        return field if signature && signature.cos_object.same?(sig_object.cos_object)
      end
      nil
    end

    # Whether the field list already contains *signature_field*
    # (Java checkSignatureField).
    private def check_signature_field(fields : Enumerable(Interactive::Form::PDField),
                                      signature_field : Interactive::Form::PDSignatureField) : Bool
      fields.any? do |field|
        field.is_a?(Interactive::Form::PDSignatureField) &&
          field.cos_object.same?(signature_field.cos_object)
      end
    end

    # Whether the annotation list already contains *widget*
    # (Java checkSignatureAnnotation).
    private def check_signature_annotation(annotations : Array(Interactive::Annotation::PDAnnotation),
                                           widget : Interactive::Annotation::PDAnnotationWidget) : Bool
      annotations.any?(&.cos_object.same?(widget.cos_object))
    end

    # An invisible signature gets a zero-sized rectangle but still needs an
    # (empty) appearance stream (Java prepareNonVisibleSignature).
    private def prepare_non_visible_signature(first_widget : Interactive::Annotation::PDAnnotationWidget) : Nil
      first_widget.rectangle = Common::PDRectangle.new
      appearance_dictionary = Interactive::Annotation::PDAppearanceDictionary.new
      appearance_stream = Interactive::Annotation::PDAppearanceStream.new(
        Common::PDStream.new(self).cos_object
      )
      appearance_stream.bbox = Common::PDRectangle.new
      appearance_dictionary.normal_appearance = appearance_stream
      first_widget.appearance = appearance_dictionary
    end

    # Takes the rectangle, appearance dictionary and default resources from the
    # visual-signature template (Java prepareVisibleSignature).
    #
    # Divergence: Java scans the template's COS object pool; this port walks the
    # template's annotations and signature fields instead, which finds the same
    # objects for a template built by PDFTemplateCreator.
    private def prepare_visible_signature(first_widget : Interactive::Annotation::PDAnnotationWidget,
                                          acro_form : Interactive::Form::PDAcroForm,
                                          visual_signature : Document) : Nil
      annotation_found = false
      signature_field_found = false

      visual_signature.pages.each do |visual_page|
        visual_page.annotations.each do |annot|
          dictionary = annot.cos_object
          if !annotation_found && named_value?(dictionary, "Annot")
            assign_signature_rectangle(first_widget, dictionary)
            annotation_found = true
          end
        end
      end

      if visual_catalog = visual_signature.document_catalog
        if visual_form = visual_catalog.acro_form(nil)
          visual_form.get_field_tree.each do |field|
            next if signature_field_found
            dictionary = field.cos_object
            next unless named_value?(dictionary, "Sig", key: "FT")

            appearance = dictionary[Cos::Name.new("AP")]
            appearance = appearance.object if appearance.is_a?(Cos::Object)
            next unless appearance.is_a?(Cos::Dictionary)

            assign_appearance_dictionary(first_widget, appearance)
            assign_acro_form_default_resource(acro_form, dictionary)
            signature_field_found = true
          end
        end
      end

      unless annotation_found && signature_field_found
        raise ArgumentError.new("Template is missing required objects")
      end
    end

    # Reads the template's /Rect for the widget unless it already has one
    # (Java assignSignatureRectangle).
    private def assign_signature_rectangle(first_widget : Interactive::Annotation::PDAnnotationWidget,
                                           annotation_dict : Cos::Dictionary) : Nil
      existing = first_widget.rectangle
      return if existing && existing.cos_object.size == 4

      rect_array = annotation_dict.get_array(Cos::Name.new("Rect"))
      return unless rect_array

      first_widget.rectangle = Common::PDRectangle.new(rect_array)
    end

    # Reads the template's /AP and makes it a direct object
    # (Java assignAppearanceDictionary).
    private def assign_appearance_dictionary(first_widget : Interactive::Annotation::PDAnnotationWidget,
                                             appearance_dict : Cos::Dictionary) : Nil
      appearance = Interactive::Annotation::PDAppearanceDictionary.new(appearance_dict)
      appearance_dict.direct = true
      first_widget.appearance = appearance
    end

    # Merges the template's AcroForm default resources /DR into the form
    # (Java assignAcroFormDefaultResource).
    private def assign_acro_form_default_resource(acro_form : Interactive::Form::PDAcroForm,
                                                  template_dict : Cos::Dictionary) : Nil
      new_dr = template_dict.get_dictionary(Cos::Name.new("DR"))
      return unless new_dr

      if default_resources = acro_form.default_resources
        old_dr = default_resources.cos_object
        new_xobject = new_dr.get_dictionary(Cos::Name.new("XObject"))
        old_xobject = old_dr.get_dictionary(Cos::Name.new("XObject"))
        if new_xobject && old_xobject
          old_xobject.add_all(new_xobject)
          old_dr.set_need_to_be_updated(true)
        end
      else
        acro_form.cos_object[Cos::Name.new("DR")] = new_dr
        new_dr.direct = true
        new_dr.set_need_to_be_updated(true)
      end
    end

    # Whether the dictionary's *key* is the given name. Java compares /Type for
    # annotations and /FT for signature fields.
    private def named_value?(dictionary : Cos::Dictionary, name : String,
                             key : String = "Type") : Bool
      value = dictionary[Cos::Name.new(key)]
      value = value.object if value.is_a?(Cos::Object)
      value.is_a?(Cos::Name) && value.value == name
    end

    # Returns this document's signature fields (Java getSignatureFields).
    def signature_fields : Array(Interactive::Form::PDSignatureField)
      fields = [] of Interactive::Form::PDSignatureField
      catalog = get_document_catalog
      return fields unless catalog
      acro_form = catalog.acro_form
      return fields unless acro_form
      acro_form.get_field_tree.each do |field|
        fields << field if field.is_a?(Interactive::Form::PDSignatureField)
      end
      fields
    end

    # Returns the signature dictionaries of the signed signature fields
    # (Java getSignatureDictionaries).
    def signature_dictionaries : Array(Interactive::Form::PDSignature)
      signatures = [] of Interactive::Form::PDSignature
      signature_fields.each do |field|
        if signature = field.signature
          signatures << signature
        end
      end
      signatures
    end

    # Returns the signature with the latest /M date (Java getLastSignatureDictionary).
    def last_signature_dictionary : Interactive::Form::PDSignature?
      last = nil.as(Interactive::Form::PDSignature?)
      signature_dictionaries.each do |signature|
        sign_date = signature.sign_date
        if last.nil?
          last = signature
        else
          last_date = last.sign_date
          if sign_date && last_date && sign_date > last_date
            last = signature
          end
        end
      end
      last
    end
  end
end
