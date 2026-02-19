require "../../spec_helper"

describe Pdfbox::Filter::Filter do
  it "round-trips randomized data through all available filters (TestFilters#testFilters)" do
    count = 10
    seed_rng = Random.new(123456_u64)

    (count * 2).times do |iter|
      seed = if iter < count
               seed_rng.next_u.to_u64
             else
               Random::Secure.rand(UInt64::MAX)
             end

      random = Random.new(seed)
      num_bytes = 10_000 + random.rand(20_000)
      original = Bytes.new(num_bytes)

      upto = 0
      while upto < num_bytes
        left = num_bytes - upto
        if random.next_bool || left < 2
          end_index = upto + Math.min(left, 10 + random.rand(100))
          while upto < end_index
            original[upto] = random.rand(256).to_u8
            upto += 1
          end
        else
          end_index = upto + Math.min(left, 2 + random.rand(10))
          value = random.rand(4).to_u8
          while upto < end_index
            original[upto] = value
            upto += 1
          end
        end
      end

      Pdfbox::Filter::FilterFactory::INSTANCE.get_all_filters.each do |filter|
        encoded = filter.encode(original)
        decoded = filter.decode(encoded)
        decoded.should eq(original)
      end
    end
  end

  it "round-trips the PDFBOX-1977 LZW regression vector (TestFilters#testPDFBOX1977)" do
    path = File.expand_path("../../resources/pdfbox/filter/PDFBOX-1977.bin", __DIR__)
    bytes = File.read(path).to_slice
    filter = Pdfbox::Filter::FilterFactory::INSTANCE.get_filter(Pdfbox::Cos::Name.new("LZWDecode"))
    encoded = filter.encode(bytes)
    decoded = filter.decode(encoded)
    decoded.should eq(bytes)
  end

  pending "loads encrypted PDF with Identity crypt filter (TestFilters#testPDFBOX4517)" do
    # Java test fixture target/pdfs/PDFBOX-4517-cryptfilter.pdf is not present in Crystal resources.
    # Expected parity: Loader.load_pdf(path, \"userpassword1234\") succeeds and page count == 1.
  end

  it "raises for an empty filter list (TestFilters#testEmptyFilterList)" do
    expect_raises(ArgumentError) do
      Pdfbox::Filter::Filter.decode(Bytes.empty, [] of Pdfbox::Filter::Filter, Pdfbox::Cos::Dictionary.new, nil, nil)
    end
  end
end
