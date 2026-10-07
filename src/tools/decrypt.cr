require "../pdfbox"
require "option_parser"

module Tools
  class Decrypt
    @password = ""
    @key_store : String? = nil
    @alias : String? = nil
    @infile : String? = nil
    @outfile : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infile = @infile
      unless infile
        @err.puts("Missing required option: -i")
        return 1
      end

      outfile = @outfile || infile # Overwrite input if no output specified

      process_document(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error decrypting document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @password = ""
      @key_store = nil
      @alias = nil
      @infile = nil
      @outfile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--alias ALIAS", "The alias to the certificate in the keystore") { |value| @alias = value }
        parser.on("--keyStore KEYSTORE", "The path to the keystore that holds the certificate to decrypt the document") { |value| @key_store = value }
        parser.on("--password PASSWORD", "The password for the PDF or certificate in keystore") { |value| @password = value }
        parser.on("-i FILE", "--input FILE", "The PDF file to decrypt (required)") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The decrypted PDF file (default: overwrite input)") { |value| @outfile = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts(<<-HELP
            Decrypts a PDF document

            This will read an encrypted document and decrypt it using a password.

            Options:
              --alias ALIAS          The alias to the certificate in the keystore
              --keyStore KEYSTORE    The path to the keystore that holds the certificate
              --password PASSWORD    The password for the PDF or certificate in keystore
              -i, --input FILE       The PDF file to decrypt (required)
              -o, --output FILE      The decrypted PDF file (default: overwrite input)
              -h, --help             Show this help
          HELP
          )
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-o", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process_document(infile : String, outfile : String) : Int32
      # Check if file exists
      unless File.exists?(infile)
        @err.puts("Error: Input file does not exist: #{infile}")
        return 1
      end

      # Load document with a password, or with a PKCS#12 keystore for
      # certificate-based decryption (Java Loader.loadPDF(infile, password,
      # keyStoreStream, alias)).
      begin
        document = if key_store = @key_store
                     unless File.exists?(key_store)
                       @err.puts("Error: Keystore does not exist: #{key_store}")
                       return 1
                     end
                     File.open(key_store) do |key_store_io|
                       Pdfbox::Loader.load_pdf(File.read(infile).to_slice, @password, key_store_io, @alias)
                     end
                   else
                     Pdfbox::Loader.load_pdf(infile, @password)
                   end

        # Check if document is encrypted
        unless document.encryption
          @err.puts("Error: Document is not encrypted.")
          return 1
        end

        # Check if we have owner permission
        ap = document.current_access_permission
        unless ap.owner_permission?
          @err.puts("Error: You are only allowed to decrypt a document with the owner password.")
          return 1
        end

        # Remove security and save
        document.set_all_security_to_be_removed(true)
        document.save(outfile)

        @out.puts("Successfully decrypted #{infile} to #{outfile}") if @out.tty?
        0
      rescue ex : Exception
        # Check if it's a password error
        if ex.message.to_s.downcase.includes?("password") || ex.message.to_s.downcase.includes?("encrypt")
          @err.puts("Error: Incorrect password or unable to decrypt document")
        else
          @err.puts("Error decrypting document: #{ex.message}")
        end
        4
      end
    end
  end
end
