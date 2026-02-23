# This class holds all of the name trees that are available at the document level.
require "./pdname_tree_node"
require "../interactive/action/pdaction_javascript"

module Pdfbox::Pdmodel::Common
  class PDJavascriptNameTreeNode < PDNameTreeNode(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    # Constructor.
    def initialize
      super
    end

    # Constructor.
    #
    # @param dic The COS dictionary.
    def initialize(dic : Cos::Dictionary)
      super(dic)
    end

    protected def convert_cos_to_pd(base : Cos::Base) : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript
      unless base.is_a?(Cos::Dictionary)
        raise ::IO::Error.new("Error creating Javascript object, expected a COSDictionary and not #{base}")
      end
      # Placeholder: create PDActionJavaScript with dictionary
      Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new(base)
    end

    protected def create_child_node(dic : Cos::Dictionary) : PDNameTreeNode(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
      PDJavascriptNameTreeNode.new(dic)
    end
  end
end
