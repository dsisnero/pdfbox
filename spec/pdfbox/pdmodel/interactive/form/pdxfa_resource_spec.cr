require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Form::PDXFAResource do
  it "reads bytes from a single XFA stream" do
    stream = Pdfbox::Cos::Stream.new
    stream.data = "<xdp:xdp xmlns:xdp=\"urn:xdp\"><form/></xdp:xdp>".to_slice
    resource = Pdfbox::Pdmodel::Interactive::Form::PDXFAResource.new(stream)

    String.new(resource.bytes).should contain("<form/>")
    resource.document.children.find!(&.element?).name.should eq("xdp")
  end

  it "concatenates bytes from packet arrays" do
    start_packet = Pdfbox::Cos::Stream.new
    start_packet.data = "<xdp:xdp xmlns:xdp=\"urn:xdp\">".to_slice
    form_packet = Pdfbox::Cos::Stream.new
    form_packet.data = "<form/>".to_slice
    end_packet = Pdfbox::Cos::Stream.new
    end_packet.data = "</xdp:xdp>".to_slice

    packets = Pdfbox::Cos::Array.new
    packets.add(Pdfbox::Cos::String.new("xdp:xdp"))
    packets.add(start_packet)
    packets.add(Pdfbox::Cos::String.new("form"))
    packets.add(form_packet)
    packets.add(Pdfbox::Cos::String.new("/xdp:xdp"))
    packets.add(end_packet)

    resource = Pdfbox::Pdmodel::Interactive::Form::PDXFAResource.new(packets)

    String.new(resource.bytes).should eq("<xdp:xdp xmlns:xdp=\"urn:xdp\"><form/></xdp:xdp>")
    resource.document.children.find!(&.element?).name.should eq("xdp")
  end
end
