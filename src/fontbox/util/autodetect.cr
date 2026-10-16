# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "uri"

module Fontbox
  module Util
    # Helps to autodetect/locate available operating system fonts.
    # Port of the org.apache.fontbox.util.autodetect package.
    module Autodetect
      Log = ::Log.for("Fontbox::Util::Autodetect")

      # A finder of native font directories.
      abstract class FontDirFinder
        abstract def find : Array(::Path)
      end

      # Native font finder base class. Reports the searchable directories that
      # actually exist and are readable.
      abstract class NativeFontDirFinder < FontDirFinder
        def find : Array(::Path)
          font_dir_list = [] of ::Path
          searchable_directories = get_searchable_directories
          if searchable_directories
            searchable_directories.each do |directory|
              if font_dir = readable_dir(directory)
                font_dir_list << font_dir
              end
            end
          end
          font_dir_list
        end

        private def readable_dir(directory : String) : ::Path?
          font_dir = ::Path.new(directory)
          return font_dir if File.exists?(font_dir) && File::Info.readable?(font_dir)
          nil
        rescue ex : File::Error
          Log.debug { "Couldn't get native font directories - ignoring: #{ex.message}" }
          nil
        end

        abstract def get_searchable_directories : Array(String)? # ameba:disable Naming/AccessorMethodName
      end

      # Mac font directory finder (based on the Apache FOP finder).
      class MacFontDirFinder < NativeFontDirFinder
        def get_searchable_directories : Array(String)? # ameba:disable Naming/AccessorMethodName
          home = ::Path.home.to_s
          [
            "#{home}/Library/Fonts/",  # user
            "/Library/Fonts/",         # local
            "/System/Library/Fonts/",  # system
            "/Network/Library/Fonts/", # network
          ]
        end
      end

      # Unix font directory finder (based on the Apache FOP finder).
      class UnixFontDirFinder < NativeFontDirFinder
        def get_searchable_directories : Array(String)? # ameba:disable Naming/AccessorMethodName
          home = ::Path.home.to_s
          [
            "#{home}/.fonts",           # user
            "/usr/local/fonts",         # local
            "/usr/local/share/fonts",   # local shared
            "/usr/share/fonts",         # system
            "/usr/X11R6/lib/X11/fonts", # X
            "/usr/share/X11/fonts",     # CentOS
          ]
        end
      end

      # Font finder for OS/400 systems.
      class OS400FontDirFinder < NativeFontDirFinder
        def get_searchable_directories : Array(String)? # ameba:disable Naming/AccessorMethodName
          home = ::Path.home.to_s
          [
            "#{home}/.fonts", # user
            "/QIBM/ProdData/OS400/Fonts",
          ]
        end
      end

      # FontFinder for native Windows platforms (based on the Apache FOP finder).
      class WindowsFontDirFinder < FontDirFinder
        def find : Array(::Path)
          font_dir_list = [] of ::Path
          windir = ENV["windir"]?
          windir = windir.rchop("/") if windir.try(&.ends_with?("/"))

          if windir && windir.size > 2
            os_fonts_dir = ::Path.new(File.join(windir, "FONTS"))
            font_dir_list << os_fonts_dir if File.exists?(os_fonts_dir) && File::Info.readable?(os_fonts_dir)

            ps_fonts_dir = ::Path.new(File.join(windir[0, 2], "PSFONTS"))
            font_dir_list << ps_fonts_dir if File.exists?(ps_fonts_dir) && File::Info.readable?(ps_fonts_dir)
          else
            windows_dir_name = (ENV["OS"]? || "").ends_with?("NT") ? "WINNT" : "WINDOWS"
            ('C'..'E').each do |drive_letter|
              os_fonts_dir = ::Path.new(File.join("#{drive_letter}:", windows_dir_name, "FONTS"))
              if File.exists?(os_fonts_dir) && File::Info.readable?(os_fonts_dir)
                font_dir_list << os_fonts_dir
                break
              end
            end
            ('C'..'E').each do |drive_letter|
              ps_fonts_dir = ::Path.new(File.join("#{drive_letter}:", "PSFONTS"))
              if File.exists?(ps_fonts_dir) && File::Info.readable?(ps_fonts_dir)
                font_dir_list << ps_fonts_dir
                break
              end
            end
          end

          if local_app_data = ENV["LOCALAPPDATA"]?
            unless local_app_data.empty?
              local_font_dir = ::Path.new(File.join(local_app_data, "Microsoft", "Windows", "Fonts"))
              font_dir_list << local_font_dir if File.exists?(local_font_dir) && File::Info.readable?(local_font_dir)
            end
          end

          font_dir_list
        end
      end

      # Helps to autodetect/locate available operating system fonts
      # (based on the Apache FOP finder).
      class FontFileFinder
        @font_dir_finder : FontDirFinder?

        def initialize
          @font_dir_finder = nil
        end

        private def determine_dir_finder : FontDirFinder
          {% if flag?(:win32) %}
            WindowsFontDirFinder.new
          {% elsif flag?(:darwin) %}
            MacFontDirFinder.new
          {% else %}
            UnixFontDirFinder.new
          {% end %}
        end

        # Automagically finds a list of font files on the local system.
        def find : Array(URI)
          @font_dir_finder ||= determine_dir_finder
          results = [] of URI
          if dir_finder = @font_dir_finder
            dir_finder.find.each do |dir|
              walk(dir, results)
            end
          end
          results
        end

        # Searches a given directory for font files.
        def find(dir : String) : Array(URI)
          results = [] of URI
          directory = ::Path.new(dir)
          walk(directory, results) if File.directory?(directory)
          results
        end

        # Walks down the directory tree and searches for font files.
        private def walk(directory : ::Path, results : Array(URI)) : Nil
          return unless File.directory?(directory)

          entries = Dir.children(directory)
          entries.each do |name|
            file = directory / name
            if File.directory?(file)
              # skip hidden directories
              next if hidden?(file)

              walk(file, results)
            elsif check_fontfile(file)
              results << file.to_uri
            end
          end
        end

        # Check if the given name belongs to a font file.
        private def check_fontfile(file : ::Path) : Bool
          name = File.basename(file).downcase
          (name.ends_with?(".ttf") || name.ends_with?(".otf") || name.ends_with?(".pfb") || name.ends_with?(".ttc")) &&
            # PDFBOX-3377 exclude weird files in AIX
            !name.starts_with?("fonts.")
        end

        private def hidden?(path : ::Path) : Bool
          File.basename(path).starts_with?(".")
        end
      end
    end
  end
end
