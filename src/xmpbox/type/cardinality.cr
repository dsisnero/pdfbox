module Xmpbox
  module Type
    enum Cardinality
      Simple
      Bag
      Seq
      Alt

      def array?
        !simple?
      end
    end
  end
end
