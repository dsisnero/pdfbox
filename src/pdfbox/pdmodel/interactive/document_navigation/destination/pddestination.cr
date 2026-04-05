module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  abstract class PDDestination
    include Pdfbox::Pdmodel::Common::PDDestinationOrAction

    def self.create(base : Cos::Base?) : PDDestination?
      case base
      when nil
        nil
      when Cos::Array
        type = base[1]?.as?(Cos::Name).try(&.value)
        case type
        when PDPageFitDestination::TYPE, PDPageFitDestination::TYPE_BOUNDED
          PDPageFitDestination.new(base)
        when PDPageFitHeightDestination::TYPE, PDPageFitHeightDestination::TYPE_BOUNDED
          PDPageFitHeightDestination.new(base)
        when PDPageFitWidthDestination::TYPE, PDPageFitWidthDestination::TYPE_BOUNDED
          PDPageFitWidthDestination.new(base)
        when PDPageFitRectangleDestination::TYPE
          PDPageFitRectangleDestination.new(base)
        when PDPageXYZDestination::TYPE
          PDPageXYZDestination.new(base)
        else
          PDPageDestination.new(base)
        end
      when Cos::String
        PDNamedDestination.new(base)
      when Cos::Name
        PDNamedDestination.new(base)
      else
        raise ::IO::Error.new("Error: can't convert to Destination #{base}")
      end
    end
  end
end
