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

module Pdfbox::Util
  # Raised when a ByteTrie node already has a value (Java IllegalStateException).
  class IllegalStateError < Exception
  end

  # A node in the trie. Has children and may have an associated value.
  # Corresponds to the nested ByteTrieNode of Apache PDFBox ByteTrie.
  class ByteTrieNode(T)
    getter children : Hash(UInt8, ByteTrieNode(T)) = Hash(UInt8, ByteTrieNode(T)).new
    @value : T?

    def value : T?
      @value
    end

    def set_value(value : T) : Nil # ameba:disable Naming/AccessorMethodName
      raise IllegalStateError.new("Value already set for this trie node") if @value
      @value = value
    end
  end

  # Stores values using a prefix tree (aka 'trie', i.e. reTRIEval data structure).
  # Port of Apache PDFBox ByteTrie (code taken from metadata-extractor).
  class ByteTrie(T)
    @root : ByteTrieNode(T)
    @max_depth : Int32

    def initialize
      @root = ByteTrieNode(T).new
      @max_depth = 0
    end

    # Return the most specific value stored for this byte sequence. If not found,
    # returns nil (or the default value set via #set_default_value).
    def find(bytes : Bytes) : T?
      node = @root
      val = node.value
      bytes.each do |byte|
        child = node.children[byte]?
        break unless child

        node = child
        val = node.value if node.value
      end
      val
    end

    # Store the given value at the specified path.
    def add_path(value : T, *parts : Bytes) : Nil
      depth = 0
      node = @root
      parts.each do |part|
        part.each do |byte|
          child = node.children[byte]?
          unless child
            child = ByteTrieNode(T).new
            node.children[byte] = child
          end
          node = child
          depth += 1
        end
      end
      node.set_value(value)
      @max_depth = Math.max(@max_depth, depth)
    end

    # Sets the default value to use in #find when no path matches.
    def set_default_value(default_value : T) : Nil # ameba:disable Naming/AccessorMethodName
      @root.set_value(default_value)
    end

    # Gets the maximum depth stored in this trie.
    def max_depth : Int32
      @max_depth
    end
  end
end
