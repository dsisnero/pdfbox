require "../../../spec_helper"

describe Fontbox::TTF::Gsub::DefaultGsubWorker do
  it "returns an immutable array that matches Java's Collections.unmodifiableList behavior" do
    worker = Fontbox::TTF::Gsub::DefaultGsubWorker.new
    original_glyph_ids = [1, 2, 3, 4, 5]

    result = worker.apply_transforms(original_glyph_ids)

    # Should have same content
    result.should eq(original_glyph_ids)

    # Should be an ImmutableArray
    result.should be_a(Fontbox::TTF::Gsub::ImmutableArray(Int32))

    # Should raise when attempting modification (matching Java's UnsupportedOperationException)
    expect_raises(Fontbox::TTF::Gsub::ImmutableArray::ImmutableError, "Cannot modify immutable array") do
      result << 6
    end

    # Original should remain unchanged
    original_glyph_ids.should eq([1, 2, 3, 4, 5])
  end
end
