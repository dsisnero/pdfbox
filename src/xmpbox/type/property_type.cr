module Xmpbox
  module Type
    # Represents @PropertyType Java annotation as a Crystal struct
    record PropertyTypeDesc, type : Types, card : Cardinality = Cardinality::Simple do
      def to_s(io : IO) : Nil
        io << "{type: " << type.to_s << ", card: " << card.to_s << '}'
      end
    end
  end
end
