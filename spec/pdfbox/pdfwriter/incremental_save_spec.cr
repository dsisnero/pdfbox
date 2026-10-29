require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/cos/TestCOSIncrement.java
#     testIncrementallyCreateDocument / testSubsetting drive the same flow
#     against document.saveIncremental(output), which appends a new revision
#     to the bytes the document was loaded from.
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/COSWriter.java
#     incremental constructor (compressParameters = NO_COMPRESSION, output
#     positioned after the source bytes) and doWriteXRefInc (new xref section
#     with /Prev = the original startxref; xref stream when the source used
#     one, classic xref table otherwise).
#
# `TestCOSIncrement` itself is ported in spec/pdfbox/cos/increment_spec.cr, but
# it only round-trips the document, so it also passed while save_incremental
# silently rewrote the whole file. These examples pin the defining property of
# an incremental update: the source bytes are kept as a prefix of the output
# and a further xref section (with /Prev) is appended.
private def incremental_find(bytes : Bytes, needle : Bytes, from : Int32 = 0) : Int32?
  return nil if needle.empty?
  limit = bytes.size - needle.size
  index = from
  while index <= limit
    if bytes[index] == needle[0]
      matched = true
      offset = 1
      while offset < needle.size
        unless bytes[index + offset] == needle[offset]
          matched = false
          break
        end
        offset += 1
      end
      return index if matched
    end
    index += 1
  end
  nil
end

private def incremental_revision_count(bytes : Bytes) : Int32
  needle = "%%EOF".to_slice
  count = 0
  offset = 0
  while (index = incremental_find(bytes, needle, offset))
    count += 1
    offset = index + needle.size
  end
  count
end

private def incremental_start_xref(bytes : Bytes) : Int64
  # Byte-level scan: the body may contain binary streams, so no regex.
  needle = "startxref".to_slice
  index = 0
  last = nil
  while (found = incremental_find(bytes, needle, index))
    last = found
    index = found + needle.size
  end
  raise "no startxref trailer in #{bytes.size} bytes" unless last

  position = last + needle.size
  while position < bytes.size && bytes[position].unsafe_chr.ascii_whitespace?
    position += 1
  end
  value = 0_i64
  while position < bytes.size && bytes[position] >= 48_u8 && bytes[position] <= 57_u8
    value = value * 10 + (bytes[position] - 48)
    position += 1
  end
  value
end

private def incremental_page(width : Float64) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(width, width)
  page
end

# Base document saved with the requested compression setting; returns the bytes.
private def incremental_base_document(compress : Bool) : Bytes
  output = IO::Memory.new
  document = Pdfbox::Pdmodel::Document.create
  document.add_page(incremental_page(100.0))
  if compress
    document.save(output)
  else
    document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
  end
  document.close
  output.to_slice
end

describe "Pdfbox::Pdfwriter incremental save" do
  it "appends a revision and keeps the original bytes as a prefix" do
    original = incremental_base_document(compress: true)
    original_start_xref = incremental_start_xref(original)
    original_revisions = incremental_revision_count(original)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.add_page(incremental_page(200.0))
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    # The original file is the prefix of the updated one (the whole point of an
    # incremental update: earlier revisions stay byte-identical).
    updated[0, original.size].should eq(original)
    incremental_revision_count(updated).should eq(original_revisions + 1)
    String.new(updated[original.size..]).should contain("/Prev #{original_start_xref}")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(2)
      reloaded.get_page(1).media_box.not_nil!.width.should eq(200.0)
    ensure
      reloaded.close
    end
  end

  it "keeps every earlier revision loadable" do
    original = incremental_base_document(compress: true)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.add_page(incremental_page(200.0))
    document.save_incremental(output)
    document.close

    # The original revision is still complete on its own.
    first_revision = Pdfbox::Loader.load_pdf(original)
    begin
      first_revision.number_of_pages.should eq(1)
    ensure
      first_revision.close
    end

    # ... and the truncated-at-original-length updated file still loads as the
    # first revision only.
    updated = output.to_slice
    truncated = Pdfbox::Loader.load_pdf(updated[0, original.size])
    begin
      truncated.number_of_pages.should eq(1)
    ensure
      truncated.close
    end

    full = Pdfbox::Loader.load_pdf(updated)
    begin
      full.number_of_pages.should eq(2)
    ensure
      full.close
    end
  end

  it "writes a classic xref table when the source used one" do
    original = incremental_base_document(compress: false)
    original_start_xref = incremental_start_xref(original)
    # Precondition: the source really uses a classic table.
    String.new(original[original_start_xref.to_i, 5]).should eq("xref\n")

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.add_page(incremental_page(300.0))
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should contain("/Prev #{original_start_xref}")
    appended.should contain("xref\n")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(2)
    ensure
      reloaded.close
    end
  end

  it "writes an xref stream when the source used one" do
    original = incremental_base_document(compress: true)
    original_start_xref = incremental_start_xref(original)
    # Precondition: the source really uses an xref stream.
    String.new(original[original_start_xref.to_i, 4]).should_not eq("xref")

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.add_page(incremental_page(400.0))
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should contain("/Type /XRef")
    appended.should contain("/Prev #{original_start_xref}")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(2)
    ensure
      reloaded.close
    end
  end

  it "carries modifications of existing objects into the new revision" do
    original = incremental_base_document(compress: true)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.get_page(0).media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(42.0, 42.0)
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    updated[0, original.size].should eq(original)

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(42.0)
    ensure
      reloaded.close
    end
  end

  it "chains several revisions" do
    original = incremental_base_document(compress: true)
    revisions = [original]
    bytes = original

    3.times do |index|
      output = IO::Memory.new
      document = Pdfbox::Loader.load_pdf(bytes)
      document.add_page(incremental_page(500.0 + index))
      document.save_incremental(output)
      document.close
      bytes = output.to_slice
      revisions << bytes
    end

    revisions.each_with_index do |revision, index|
      # Every revision starts with its predecessor, byte for byte.
      if index.positive?
        previous = revisions[index - 1]
        revision[0, previous.size].should eq(previous)
        incremental_revision_count(revision).should eq(incremental_revision_count(previous) + 1)
      end

      reloaded = Pdfbox::Loader.load_pdf(revision)
      begin
        reloaded.number_of_pages.should eq(1 + index)
      ensure
        reloaded.close
      end
    end
  end

  it "appends to a document loaded from a random-access source" do
    original = incremental_base_document(compress: true)
    original_start_xref = incremental_start_xref(original)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(Pdfbox::IO::RandomAccessReadBuffer.new(original))
    begin
      document.add_page(incremental_page(600.0))
      document.save_incremental(output)
    ensure
      document.close
    end

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    String.new(updated[original.size..]).should contain("/Prev #{original_start_xref}")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(2)
    ensure
      reloaded.close
    end
  end

  # COSWriter#write collects the objects to write with
  #   trailer.toIncrement().exclude(trailer)
  # so an incremental update only carries the objects that were changed (plus
  # the objects created in this session). Without COSUpdateState tracking the
  # appended revision would be a full rewrite of every reachable object.
  it "writes no object bodies when the document was not modified" do
    # Classic xref table: the appended revision then contains nothing but the
    # cross-reference section and the trailer.
    original = incremental_base_document(compress: false)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should_not contain(" obj\n")
    appended.should contain("/Prev #{incremental_start_xref(original)}")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(100.0)
    ensure
      reloaded.close
    end
  end

  it "writes only the modified objects into the new revision" do
    original = incremental_base_document(compress: true)

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    document.get_page(0).media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(42.0, 42.0)
    document.save_incremental(output)
    document.close

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    # The changed page dictionary is written ...
    appended.should contain("/MediaBox")
    # ... and nothing else: a full rewrite would carry the catalog, page tree,
    # trailer references and every stream.
    appended.should_not contain("/Type /Catalog")
    appended.should_not contain("/Type /Pages")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(42.0)
    ensure
      reloaded.close
    end
  end

  # Java keeps DocumentInformation changes incremental: only the /Info dictionary
  # is appended, the rest of the document is left untouched.
  it "appends only the document information object when the metadata changed" do
    output = IO::Memory.new
    document = Pdfbox::Pdmodel::Document.create
    document.add_page(incremental_page(100.0))
    information = Pdfbox::Pdmodel::DocumentInformation.new
    information.title = "Original Title"
    document.set_document_information(information)
    document.save(output, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    document.close
    original = output.to_slice

    incremental = IO::Memory.new
    loaded = Pdfbox::Loader.load_pdf(original)
    begin
      loaded.document_information.not_nil!.title.should eq("Original Title")
      loaded.document_information.not_nil!.title = "Incremental Title"
      loaded.save_incremental(incremental)
    ensure
      loaded.close
    end

    updated = incremental.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should contain("Incremental Title")
    appended.should_not contain("/Type /Catalog")
    appended.should_not contain("/Type /Pages")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.document_information.not_nil!.title.should eq("Incremental Title")
      reloaded.number_of_pages.should eq(1)
    ensure
      reloaded.close
    end
  end

  # Java PDDocument#saveIncremental(OutputStream, Set<COSDictionary>) is for
  # "experienced users": it writes the listed dictionaries even when nothing has
  # isNeedToBeUpdated() set, which keeps the appended revision minimal (e.g.
  # changing a signed file without invalidating the signature). Upstream has no
  # unit test for the overload, so these examples pin the Java semantics
  # (only COSDictionary entries, union with the update-flag set, no duplicates).
  it "writes an explicitly listed object even when nothing was changed" do
    original = incremental_base_document(compress: false)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    begin
      page_dictionary = document.get_page(0).cos_object.not_nil!
      document.save_incremental(output, [page_dictionary])
    ensure
      document.close
    end

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should contain("/Type /Page")
    appended.should_not contain("/Type /Catalog")
    appended.should_not contain("/Type /Pages")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(100.0)
    ensure
      reloaded.close
    end
  end

  it "writes no object bodies for an empty explicit list" do
    original = incremental_base_document(compress: false)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    begin
      document.save_incremental(output, [] of Pdfbox::Cos::Dictionary)
    ensure
      document.close
    end

    updated = output.to_slice
    updated[0, original.size].should eq(original)
    appended = String.new(updated[original.size..])
    appended.should_not contain(" obj\n")
    appended.should contain("/Prev #{incremental_start_xref(original)}")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.number_of_pages.should eq(1)
    ensure
      reloaded.close
    end
  end

  it "writes the union of the changed objects and the explicit list exactly once" do
    original = incremental_base_document(compress: false)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    page_key = nil.as(Pdfbox::Cos::ObjectKey?)
    begin
      page = document.get_page(0)
      page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(23.0, 23.0)
      page_dictionary = page.cos_object.not_nil!
      page_key = page_dictionary.key
      # the same page dictionary is both changed and listed
      document.save_incremental(output, [page_dictionary])
    ensure
      document.close
    end

    updated = output.to_slice
    appended = String.new(updated[original.size..])
    appended.should contain("/MediaBox")
    # Listing an already-changed dictionary must not write it twice.
    key = page_key.not_nil!
    appended.scan(/\n#{key.number} #{key.generation} obj\n/).size.should eq(1)
    appended.should_not contain("/Type /Catalog")

    reloaded = Pdfbox::Loader.load_pdf(updated)
    begin
      reloaded.get_page(0).media_box.not_nil!.width.should eq(23.0)
    ensure
      reloaded.close
    end
  end

  it "falls back to a full save for a document that has no source bytes" do
    output = IO::Memory.new
    document = Pdfbox::Pdmodel::Document.create
    document.add_page(incremental_page(120.0))
    document.save_incremental(output)
    document.close

    reloaded = Pdfbox::Loader.load_pdf(output.to_slice)
    begin
      reloaded.number_of_pages.should eq(1)
      reloaded.get_page(0).media_box.not_nil!.width.should eq(120.0)
    ensure
      reloaded.close
    end
  end

  # Java COSWriter writes created direct structures inline (only COSObject values
  # become indirect), so replacing a page's /MediaBox appends the page dictionary
  # and nothing else. The port used to give every new array its own object number,
  # which added an orphan object to every such revision.
  it "inlines a created structure instead of writing it as its own object" do
    original = incremental_base_document(compress: false)
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(original)
    begin
      document.get_page(0).media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(42.0, 42.0)
      document.save_incremental(output)
    ensure
      document.close
    end

    appended = String.new(output.to_slice[original.size..])
    appended.scan(/\n\d+ \d+ obj\n/).size.should eq(1)
    appended.should contain("/MediaBox")
    appended.should contain("/MediaBox [0.0 0.0 42.0 42.0]")

    reloaded = Pdfbox::Loader.load_pdf(output.to_slice)
    begin
      reloaded.get_page(0).media_box.not_nil!.width.should eq(42.0)
    ensure
      reloaded.close
    end
  end
end
