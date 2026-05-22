require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Type
    describe "Structured types" do
      xmp = XMPMetadata.create_xmp_metadata

      it "JobType properties start nil" do
        job = JobType.new(xmp)
        job.id.should be_nil
        job.name.should be_nil
        job.url.should be_nil
      end

      it "JobType set and get properties" do
        job = JobType.new(xmp)
        job.id = "job-1"
        job.name = "MyJob"
        job.url = "http://example.com/job"

        job.id.should eq("job-1")
        job.name.should eq("MyJob")
        job.url.should eq("http://example.com/job")
      end

      it "ThumbnailType properties start nil" do
        thumb = ThumbnailType.new(xmp)
        thumb.format.should be_nil
        thumb.height.should be_nil
        thumb.width.should be_nil
        thumb.image.should be_nil
      end

      it "ThumbnailType set and get properties" do
        thumb = ThumbnailType.new(xmp)
        thumb.height = 100
        thumb.width = 200
        thumb.image = "base64data"
        thumb.format = "JPEG"

        thumb.height.should eq(100)
        thumb.width.should eq(200)
        thumb.image.should eq("base64data")
        thumb.format.should eq("JPEG")
      end

      it "ResourceEventType set and get properties" do
        evt = ResourceEventType.new(xmp)
        evt.action = "converted"
        evt.changed = "/metadata"
        evt.instance_id = "uuid:123"
        evt.parameters = ""
        evt.software_agent = "PDFBox"

        evt.action.should eq("converted")
        evt.changed.should eq("/metadata")
        evt.instance_id.should eq("uuid:123")
        evt.parameters.should eq("")
        evt.software_agent.should eq("PDFBox")
      end

      it "ResourceRefType set and get properties" do
        ref = ResourceRefType.new(xmp)
        ref.document_id = "doc:1"
        ref.file_path = "/path/to/file"
        ref.instance_id = "uuid:456"
        ref.manager = "Admin"
        ref.manager_variant = "A"
        ref.manage_to = "uri:target"
        ref.manage_ui = "uri:ui"
        ref.mask_markers = "None"
        ref.part_mapping = "linear"
        ref.rendition_class = "default"
        ref.rendition_params = "scale=1"
        ref.to_part = "2"
        ref.from_part = "1"
        ref.version_id = "v1.0"

        ref.document_id.should eq("doc:1")
        ref.file_path.should eq("/path/to/file")
        ref.instance_id.should eq("uuid:456")
        ref.manager.should eq("Admin")
        ref.manager_variant.should eq("A")
        ref.manage_to.should eq("uri:target")
        ref.manage_ui.should eq("uri:ui")
        ref.mask_markers.should eq("None")
        ref.part_mapping.should eq("linear")
        ref.rendition_class.should eq("default")
        ref.rendition_params.should eq("scale=1")
        ref.to_part.should eq("2")
        ref.from_part.should eq("1")
        ref.version_id.should eq("v1.0")
      end

      it "set property does not affect other properties" do
        job = JobType.new(xmp)
        job.id = "id1"

        job.id.should eq("id1")
        job.name.should be_nil
        job.url.should be_nil
      end

      it "getting property from empty type returns nil" do
        job = JobType.new(xmp)
        job.id.should be_nil
      end
    end
  end
end
