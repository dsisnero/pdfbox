require "../../../spec_helper"

describe Fontbox::TTF::Gsub::DefaultGsubWorker do
  it "returns a duplicate of the input array to prevent modification of source" do
    worker = Fontbox::TTF::Gsub::DefaultGsubWorker.new
    original_glyph_ids = [1, 2, 3, 4, 5]

    result = worker.apply_transforms(original_glyph_ids)

    # Should have same content
    result.should eq(original_glyph_ids)

    # Should be a different array (duplicate)
    original_glyph_ids.should_not be(result)

    # Modifying result should not affect original
    result << 6
    original_glyph_ids.should eq([1, 2, 3, 4, 5])
  end
end
