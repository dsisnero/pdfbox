require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of BasicJobTicketSchemaTest.java — verifies XMPBasicJobTicketSchema
    # addJob/getJobs plus serialize/parse round-trip of JobType bags.
    describe XMPBasicJobTicketSchema do
      it "adds two jobs and round-trips them" do
        meta = XMPMetadata.create_xmp_metadata
        basic = meta.create_and_add_xmp_basic_job_ticket_schema

        basic.add_job("zeid1", "zename1", "zeurl1", "aaa")
        basic.add_job("zeid2", "zename2", "zeurl2")

        serialized = Xmpbox::Xml::XmpSerializer.new.serialize(meta)
        rxmp = Xmpbox::Xml::DomXmpParser.new.parse(serialized)

        jt = rxmp.xmp_basic_job_ticket_schema
        jt.should_not be_nil
        jobs = jt.not_nil!.jobs.not_nil!
        jobs.size.should eq(2)
        jobs[0].id.should eq("zeid1")
        jobs[0].name.should eq("zename1")
        jobs[0].url.should eq("zeurl1")
        jobs[1].id.should eq("zeid2")
        jobs[1].name.should eq("zename2")
        jobs[1].url.should eq("zeurl2")
      end

      it "adds a job with default prefix and round-trips it" do
        meta = XMPMetadata.create_xmp_metadata
        basic = meta.create_and_add_xmp_basic_job_ticket_schema

        basic.add_job("zeid2", "zename2", "zeurl2")

        serialized = Xmpbox::Xml::XmpSerializer.new.serialize(meta)
        rxmp = Xmpbox::Xml::DomXmpParser.new.parse(serialized)

        jt = rxmp.xmp_basic_job_ticket_schema
        jt.should_not be_nil
        jobs = jt.not_nil!.jobs.not_nil!
        jobs.size.should eq(1)
        jobs[0].id.should eq("zeid2")
        jobs[0].name.should eq("zename2")
        jobs[0].url.should eq("zeurl2")
      end

      it "adds a job with a defined prefix and keeps its namespace/prefix" do
        meta = XMPMetadata.create_xmp_metadata
        basic = meta.create_and_add_xmp_basic_job_ticket_schema

        basic.add_job("zeid2", "zename2", "zeurl2", "aaa")

        serialized = Xmpbox::Xml::XmpSerializer.new.serialize(meta)
        rxmp = Xmpbox::Xml::DomXmpParser.new.parse(serialized)

        jt = rxmp.xmp_basic_job_ticket_schema
        jobs = jt.not_nil!.jobs.not_nil!
        jobs.size.should eq(1)
        jobs[0].id.should eq("zeid2")
        jobs[0].name.should eq("zename2")
        jobs[0].url.should eq("zeurl2")
        jobs[0].namespace.should eq(Xmpbox::Type::JobType.structured_type_info[:namespace])
        jobs[0].prefix.should eq("aaa")
      end
    end
  end
end
