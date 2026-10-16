require "../../spec_helper"
require "file_utils"

# Source of truth:
#   vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/util/autodetect/*.java
# Characterization spec for the OS font-directory autodetection package
# (upstream has no dedicated test; FontFileFinder is used by TTFSubsetterTest
# only to locate a machine-specific font).
module Fontbox
  module Util
    module Autodetect
      describe FontDirFinder do
        it "finds only existing, readable directories for the native platform" do
          finder = MacFontDirFinder.new
          dirs = finder.find

          dirs.each do |dir|
            File.directory?(dir).should be_true
            finder.get_searchable_directories.not_nil!.should contain(dir.to_s)
          end
        end
      end

      describe MacFontDirFinder do
        it "searches the standard macOS font directories" do
          dirs = MacFontDirFinder.new.get_searchable_directories.not_nil!
          home = ::Path.home.to_s

          dirs.should eq([
            "#{home}/Library/Fonts/",
            "/Library/Fonts/",
            "/System/Library/Fonts/",
            "/Network/Library/Fonts/",
          ])
        end
      end

      describe UnixFontDirFinder do
        it "searches the standard Unix font directories" do
          dirs = UnixFontDirFinder.new.get_searchable_directories.not_nil!
          home = ::Path.home.to_s

          dirs.should eq([
            "#{home}/.fonts",
            "/usr/local/fonts",
            "/usr/local/share/fonts",
            "/usr/share/fonts",
            "/usr/X11R6/lib/X11/fonts",
            "/usr/share/X11/fonts",
          ])
        end
      end

      describe OS400FontDirFinder do
        it "searches the OS/400 font directories" do
          dirs = OS400FontDirFinder.new.get_searchable_directories.not_nil!
          home = ::Path.home.to_s

          dirs.should eq(["#{home}/.fonts", "/QIBM/ProdData/OS400/Fonts"])
        end
      end

      describe FontFileFinder do
        it "finds font files recursively, skipping hidden directories and non-font files" do
          root = File.join(Dir.tempdir, "pdfbox_autodetect_#{Process.pid}_#{Random.rand(1_000_000)}")
          FileUtils.rm_rf(root)
          begin
            Dir.mkdir_p(File.join(root, "sub"))
            Dir.mkdir_p(File.join(root, ".hidden"))
            File.write(File.join(root, "good.ttf"), "")
            File.write(File.join(root, "note.txt"), "")
            File.write(File.join(root, "fonts.weird.ttf"), "")
            File.write(File.join(root, "sub", "font.otf"), "")
            File.write(File.join(root, ".hidden", "secret.ttf"), "")

            found = FontFileFinder.new.find(root).map(&.path).sort
            found.should eq([
              File.join(root, "good.ttf"),
              File.join(root, "sub", "font.otf"),
            ].sort)
          ensure
            FileUtils.rm_rf(root)
          end
        end

        it "returns nothing for a directory that does not exist" do
          FontFileFinder.new.find(File.join(Dir.tempdir, "pdfbox_missing_#{Process.pid}")).should be_empty
        end
      end
    end
  end
end
