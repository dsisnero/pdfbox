require "../cos"
require "./resource_cache"

module Pdfbox::Pdmodel
  # Placeholder for PDResources until full resource resolution is ported.
  class PDResources
    def initialize(@dict : Pdfbox::Cos::Dictionary, @resource_cache : ResourceCache? = nil)
    end
  end
end
