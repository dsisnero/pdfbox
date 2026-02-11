require "../spec_helper"

def with_test_file(&)
  Dir.mkdir_p("temp")
  path = File.join("temp", "random_access_read_spec.txt")
  File.write(path, "0123456789")
  begin
    yield path
  ensure
    File.delete(path) if File.exists?(path)
  end
end

describe Pdfbox::IO::RandomAccessReadBuffer do
  it "clamps seek to end of buffer" do
    rar = Pdfbox::IO::RandomAccessReadBuffer.new("0123456789")
    begin
      rar.seek(50)
      rar.position.should eq(10)
      rar.eof?.should be_true
    ensure
      rar.close
    end
  end

  it "peeks without advancing position" do
    rar = Pdfbox::IO::RandomAccessReadBuffer.new("0123456789")
    begin
      rar.skip(6)
      rar.position.should eq(6)
      rar.peek.should eq('6'.ord.to_u8)
      rar.position.should eq(6)
    ensure
      rar.close
    end
  end

  it "creates a view with independent position" do
    rar = Pdfbox::IO::RandomAccessReadBuffer.new("0123456789")
    view = rar.create_view(3, 4)
    begin
      view.position.should eq(0)
      view.read.should eq('3'.ord.to_u8)
      view.read.should eq('4'.ord.to_u8)
      rar.position.should eq(0)
    ensure
      view.close
      rar.close
    end
  end
end

describe Pdfbox::IO::RandomAccessReadBufferedFile do
  it "clamps seek to end of file" do
    with_test_file do |path|
      rar = Pdfbox::IO::RandomAccessReadBufferedFile.new(path)
      rar.seek(50)
      rar.position.should eq(10)
      rar.eof?.should be_true
      rar.close
    end
  end

  it "peeks without advancing position" do
    with_test_file do |path|
      rar = Pdfbox::IO::RandomAccessReadBufferedFile.new(path)
      rar.skip(6)
      rar.position.should eq(6)
      rar.peek.should eq('6'.ord.to_u8)
      rar.position.should eq(6)
      rar.close
    end
  end

  it "creates a view with independent position" do
    with_test_file do |path|
      rar = Pdfbox::IO::RandomAccessReadBufferedFile.new(path)
      view = rar.create_view(3, 4)

      view.position.should eq(0)
      view.read.should eq('3'.ord.to_u8)
      view.read.should eq('4'.ord.to_u8)
      rar.position.should eq(0)

      view.close
      rar.close
    end
  end
end
