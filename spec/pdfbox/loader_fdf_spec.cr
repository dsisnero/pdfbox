require "../spec_helper"
require "../../src/pdfbox"

describe Pdfbox::Loader do
  it "loads fdf from io through FDFParser" do
    io = IO::Memory.new("%FDF-1.2\n1 0 obj\n<< /FDF << /Fields [ << /T (name) /V (Alice) >> ] >> >>\nendobj\ntrailer\n<< /Root 1 0 R >>\n%%EOF\n")

    document = Pdfbox::Loader.load_fdf(io)

    document.catalog.fdf.fields.as(Array).first.partial_field_name.should eq("name")
    document.catalog.fdf.fields.as(Array).first.value.should eq("Alice")
  end

  it "loads xfdf from io" do
    io = IO::Memory.new(%(<?xml version="1.0" encoding="UTF-8"?>\n<xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve"><fields><field name="name"><value>Alice</value></field></fields></xfdf>\n))

    document = Pdfbox::Loader.load_xfdf(io)

    document.catalog.fdf.fields.as(Array).first.partial_field_name.should eq("name")
    document.catalog.fdf.fields.as(Array).first.value.should eq("Alice")
  end
end
