module Pdfbox::Pdmodel
  # Signature-related helpers on PDDocument (Java PDDocument#getSignatureFields,
  # getSignatureDictionaries, getLastSignatureDictionary).
  class Document
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
