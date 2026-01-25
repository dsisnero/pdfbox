# I/O utilities for PDFBox Crystal
#
# This module contains I/O utilities for PDF processing,
# corresponding to the io module in Apache PDFBox.
module Pdfbox::IO
  # I/O utility functions
  module Utils
    # Copy data from one IO to another
    def self.copy(input : ::IO, output : ::IO, buffer_size : Int = 8192) : Int64
      total = 0_i64
      buffer = Bytes.new(buffer_size)

      while (read = input.read(buffer)) > 0
        output.write(buffer[0, read])
        total += read
      end

      total
    end

    # Read all bytes from an IO
    def self.to_byte_array(io : ::IO) : Bytes
      io.rewind if io.responds_to?(:rewind)
      buffer = ::IO::Memory.new
      copy(io, buffer)
      buffer.to_slice
    end

    # Read all text from an IO with given encoding
    def self.to_string(io : ::IO, encoding : String = "UTF-8") : String
      io.rewind if io.responds_to?(:rewind)
      ::String.new(to_byte_array(io), encoding)
    end

    # Close an IO resource silently (ignore errors)
    def self.close_quietly(io : ::IO?) : Nil
      io.try(&.close)
    rescue
      # Ignore close errors
    end

    # Close multiple IO resources silently
    def self.close_quietly(ios : Enumerable(::IO?)) : Nil
      ios.each { |io| close_quietly(io) }
    end
  end

  # Random access read interface (similar to Java RandomAccessRead)
  abstract class RandomAccessRead
    # Get current position
    abstract def position : Int64

    # Get total length
    abstract def length : Int64

    # Seek to position
    abstract def seek(position : Int64) : Nil

    # Read byte at current position and advance
    abstract def read : UInt8?

    # Read bytes into buffer
    abstract def read(buffer : Bytes) : Int32

    # Read byte at position without advancing
    abstract def peek : UInt8?

    # Check if at end of stream
    abstract def eof? : Bool

    # Rewind to beginning
    def rewind : Nil
      seek(0)
    end

    # Read all remaining bytes
    def read_all : Bytes
      buffer = Bytes.new(length - position)
      read(buffer)
      buffer
    end
  end

  # Random access read implementation using ::IO::Memory
  class MemoryRandomAccessRead < RandomAccessRead
    @io : ::IO::Memory

    def initialize(data : Bytes | String = Bytes.empty)
      @io = ::IO::Memory.new(data)
    end

    def position : Int64
      @io.pos.to_i64
    end

    def length : Int64
      @io.size.to_i64
    end

    def seek(position : Int64) : Nil
      @io.pos = position
    end

    def read : UInt8?
      byte = @io.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      @io.read(buffer)
    end

    def peek : UInt8?
      slice = @io.peek
      slice.nil? ? nil : slice.first?
    end

    def eof? : Bool
      @io.pos >= @io.size
    end
  end

  # Random access read implementation using ::File
  class FileRandomAccessRead < RandomAccessRead
    @file : ::File

    def initialize(filename : String)
      @file = ::File.open(filename, "r")
    end

    def position : Int64
      @file.pos.to_i64
    end

    def length : Int64
      @file.size.to_i64
    end

    def seek(position : Int64) : Nil
      @file.pos = position
    end

    def read : UInt8?
      byte = @file.read_byte
      byte.nil? ? nil : byte
    end

    def read(buffer : Bytes) : Int32
      @file.read(buffer)
    end

    def peek : UInt8?
      current_pos = @file.pos
      byte = read
      @file.pos = current_pos
      byte
    end

    def eof? : Bool
      @file.pos >= @file.size
    end

    def finalize
      @file.close
    end
  end
end
