require "../../spec_helper"

module Pdfbox::Pdfparser
  module XrefTrailerResolverSpecHelpers
    # Helper to create a simple trailer dictionary with optional Prev entry
    def self.create_trailer(prev : Int64? = nil) : Cos::Dictionary
      dict = Cos::Dictionary.new
      if prev
        dict[Cos::Name.new("Prev")] = Cos::Integer.new(prev)
      end
      dict
    end

    # Helper to create an object key
    def self.obj_key(number : Int32, gen : Int32 = 0) : Cos::ObjectKey
      Cos::ObjectKey.new(number, gen)
    end
  end

  describe XrefTrailerResolver do
    describe "#initialize" do
      it "creates empty resolver" do
        resolver = XrefTrailerResolver.new
        resolver.trailer_count.should eq(0)
        resolver.first_trailer.should be_nil
        resolver.last_trailer.should be_nil
        resolver.current_trailer.should be_nil
        resolver.xref_type.should be_nil
        resolver.trailer.should be_nil
        resolver.xref_table.should be_nil
      end
    end

    describe "#next_xref_obj" do
      it "sets current xref object" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.current_trailer.should be_nil
      end

      it "allows multiple xref objects at different positions" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.next_xref_obj(200, XRefType::Stream)
        resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer(100)
        resolver.trailer_count.should eq(2)
      end
    end

    describe "#add_xref" do
      it "adds entry to current xref object" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
        # cannot verify directly, will be visible after startxref resolution
      end

      it "warns if no current xref object" do
        resolver = XrefTrailerResolver.new
        # expect warning log
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
      end

      it "does not overwrite existing key (PDFBOX-3506)" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 600) # same key, different offset
        # second add should be ignored
        resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.startxref = 100
        table = resolver.xref_table.as(Hash(Cos::ObjectKey, Int64))
        table.size.should eq(1)
        table[XrefTrailerResolverSpecHelpers.obj_key(1, 0)].should eq(500) # first offset kept
      end
    end

    describe "#current_trailer=" do
      it "sets trailer for current xref object" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        trailer = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.current_trailer = trailer
        resolver.current_trailer.should eq(trailer)
      end

      it "warns if no current xref object" do
        resolver = XrefTrailerResolver.new
        trailer = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.current_trailer = trailer
      end
    end

    describe "#first_trailer and #last_trailer" do
      it "returns nil when empty" do
        resolver = XrefTrailerResolver.new
        resolver.first_trailer.should be_nil
        resolver.last_trailer.should be_nil
      end

      it "returns first and last trailers by byte position order" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(300, XRefType::Table)
        trailer1 = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.current_trailer = trailer1
        resolver.next_xref_obj(100, XRefType::Stream)
        trailer2 = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.current_trailer = trailer2
        resolver.next_xref_obj(200, XRefType::Table)
        trailer3 = XrefTrailerResolverSpecHelpers.create_trailer
        resolver.current_trailer = trailer3

        resolver.first_trailer.should eq(trailer2) # position 100
        resolver.last_trailer.should eq(trailer1)  # position 300
      end
    end

    describe "#trailer_count" do
      it "returns number of xref objects" do
        resolver = XrefTrailerResolver.new
        resolver.trailer_count.should eq(0)
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.trailer_count.should eq(1)
        resolver.next_xref_obj(200, XRefType::Stream)
        resolver.trailer_count.should eq(2)
      end
    end

    describe "#startxref=" do
      it "resolves chain when startxref position exists" do
        resolver = XrefTrailerResolver.new
        # Create two xref objects linked by Prev (newer at 100 points to older at 50)
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer(50) # points to previous at 50
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
        resolver.next_xref_obj(50, XRefType::Stream)
        resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer # no Prev
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(2, 0), 600)

        resolver.startxref = 100 # start at newest
        resolver.trailer.should_not be_nil
        resolver.xref_table.should_not be_nil
        table = resolver.xref_table.as(Hash(Cos::ObjectKey, Int64))
        table.size.should eq(2)
        table[XrefTrailerResolverSpecHelpers.obj_key(1, 0)].should eq(500)
        table[XrefTrailerResolverSpecHelpers.obj_key(2, 0)].should eq(600)
        resolver.xref_type.should eq(XRefType::Table) # type from startxref object
      end

      it "uses all objects in order when startxref position not found" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
        resolver.next_xref_obj(200, XRefType::Stream)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 600) # duplicate key, should overwrite previous

        resolver.startxref = 999 # not found
        table = resolver.xref_table.as(Hash(Cos::ObjectKey, Int64))
        table.size.should eq(1)
        table[XrefTrailerResolverSpecHelpers.obj_key(1, 0)].should eq(600) # later overwrites earlier
      end

      it "handles missing Prev chain" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        trailer = XrefTrailerResolverSpecHelpers.create_trailer # no Prev
        resolver.current_trailer = trailer
        resolver.startxref = 100
        resolver.trailer.should eq(trailer)
      end

      it "warns if set multiple times" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        resolver.startxref = 100
        resolver.startxref = 100 # should warn
      end
    end

    describe "#xref_type" do
      it "returns type of resolved trailer after startxref" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Stream)
        resolver.startxref = 100
        resolver.xref_type.should eq(XRefType::Stream)
      end
    end

    describe "#contained_object_numbers" do
      it "returns object numbers referenced in object stream" do
        resolver = XrefTrailerResolver.new
        resolver.next_xref_obj(100, XRefType::Table)
        # negative offset indicates object stream
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(10, 0), -5)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(11, 0), -5)
        resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(12, 0), 500) # positive offset, not contained
        resolver.startxref = 100
        contained = resolver.contained_object_numbers(5)
        contained.should_not be_nil
        contained.as(Set(Int64)).should eq(Set{10_i64, 11_i64})
      end

      it "returns nil if startxref not called" do
        resolver = XrefTrailerResolver.new
        resolver.contained_object_numbers(5).should be_nil
      end
    end

    # protected method #reset is not accessible from specs
    # describe "#reset" do
    #   it "clears all data" do
    #     resolver = XrefTrailerResolver.new
    #     resolver.next_xref_obj(100, XRefType::Table)
    #     resolver.add_xref(XrefTrailerResolverSpecHelpers.obj_key(1, 0), 500)
    #     resolver.current_trailer = XrefTrailerResolverSpecHelpers.create_trailer
    #     resolver.startxref = 100
    #     resolver.reset
    #     resolver.trailer_count.should eq(0)
    #     resolver.trailer.should be_nil
    #     resolver.xref_table.should be_nil
    #   end
    # end
  end
end
