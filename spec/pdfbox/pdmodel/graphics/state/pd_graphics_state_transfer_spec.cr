require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDGraphicsState.java
#     getTransfer/setTransfer (a plain field, copied by clone()).
#
# PDGraphicsState has no dedicated Java test, so the assertions below are
# derived from the Java source.
module Pdfbox::Pdmodel::Graphics::State
  describe PDGraphicsState do
    it "stores and returns the transfer function (Java getTransfer/setTransfer)" do
      state = PDGraphicsState.new
      state.transfer.should be_nil

      transfer = Cos::Dictionary.new
      state.transfer = transfer
      state.transfer.should be(transfer)

      state.transfer = nil
      state.transfer.should be_nil
    end

    it "copies the transfer function in clone() (Java clone)" do
      state = PDGraphicsState.new
      transfer = Cos::Dictionary.new
      state.transfer = transfer

      clone = state.clone
      clone.transfer.should be(transfer)
    end
  end
end
