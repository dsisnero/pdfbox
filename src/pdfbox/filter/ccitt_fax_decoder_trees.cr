# CCITT Huffman code tables and static decode trees.
# Java: org.apache.pdfbox.filter.CCITTFaxDecoderStream (static fields)

module Pdfbox::Filter
  class CCITTFaxDecoderStream
    BLACK_CODES = [
      [0x2, 0x3],
      [0x2, 0x3],
      [0x2, 0x3],
      [0x3],
      [0x4, 0x5],
      [0x4, 0x5, 0x7],
      [0x4, 0x7],
      [0x18],
      [0x17, 0x18, 0x37, 0x8, 0xf],
      [0x17, 0x18, 0x28, 0x37, 0x67, 0x68, 0x6c, 0x8, 0xc, 0xd],
      [0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1c, 0x1d, 0x1e, 0x1f, 0x24, 0x27, 0x28, 0x2b, 0x2c, 0x33,
       0x34, 0x35, 0x37, 0x38, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x64, 0x65,
       0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xd2, 0xd3,
       0xd4, 0xd5, 0xd6, 0xd7, 0xda, 0xdb],
      [0x4a, 0x4b, 0x4c, 0x4d, 0x52, 0x53, 0x54, 0x55, 0x5a, 0x5b, 0x64, 0x65, 0x6c, 0x6d, 0x72, 0x73,
       0x74, 0x75, 0x76, 0x77],
    ]

    BLACK_RUN_LENGTHS = [
      [3, 2],
      [1, 4],
      [6, 5],
      [7],
      [9, 8],
      [10, 11, 12],
      [13, 14],
      [15],
      [16, 17, 0, 18, 64],
      [24, 25, 23, 22, 19, 20, 21, 1792, 1856, 1920],
      [1984, 2048, 2112, 2176, 2240, 2304, 2368, 2432, 2496, 2560, 52, 55, 56, 59, 60, 320, 384, 448, 53,
       54, 50, 51, 44, 45, 46, 47, 57, 58, 61, 256, 48, 49, 62, 63, 30, 31, 32, 33, 40, 41, 128, 192, 26,
       27, 28, 29, 34, 35, 36, 37, 38, 39, 42, 43],
      [640, 704, 768, 832, 1280, 1344, 1408, 1472, 1536, 1600, 1664, 1728, 512, 576, 896, 960, 1024, 1088,
       1152, 1216],
    ]

    WHITE_CODES = [
      [0x7, 0x8, 0xb, 0xc, 0xe, 0xf],
      [0x12, 0x13, 0x14, 0x1b, 0x7, 0x8],
      [0x17, 0x18, 0x2a, 0x2b, 0x3, 0x34, 0x35, 0x7, 0x8],
      [0x13, 0x17, 0x18, 0x24, 0x27, 0x28, 0x2b, 0x3, 0x37, 0x4, 0x8, 0xc],
      [0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1a, 0x1b, 0x2, 0x24, 0x25, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d,
       0x3, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x4, 0x4a, 0x4b, 0x5, 0x52, 0x53, 0x54, 0x55, 0x58, 0x59,
       0x5a, 0x5b, 0x64, 0x65, 0x67, 0x68, 0xa, 0xb],
      [0x98, 0x99, 0x9a, 0x9b, 0xcc, 0xcd, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb],
      [] of Int32,
      [0x8, 0xc, 0xd],
      [0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x1c, 0x1d, 0x1e, 0x1f],
    ]

    WHITE_RUN_LENGTHS = [
      [2, 3, 4, 5, 6, 7],
      [128, 8, 9, 64, 10, 11],
      [192, 1664, 16, 17, 13, 14, 15, 1, 12],
      [26, 21, 28, 27, 18, 24, 25, 22, 256, 23, 20, 19],
      [33, 34, 35, 36, 37, 38, 31, 32, 29, 53, 54, 39, 40, 41, 42, 43, 44, 30, 61, 62, 63, 0, 320, 384, 45,
       59, 60, 46, 49, 50, 51, 52, 55, 56, 57, 58, 448, 512, 640, 576, 47, 48],
      [1472, 1536, 1600, 1728, 704, 768, 832, 896, 960, 1024, 1088, 1152, 1216, 1280, 1344, 1408],
      [] of Int32,
      [1792, 1856, 1920],
      [1984, 2048, 2112, 2176, 2240, 2304, 2368, 2432, 2496, 2560],
    ]

    private EOL = begin
      node = Node.new
      node.leaf = true
      node.value = VALUE_EOL
      node
    end

    private FILL = begin
      node = Node.new
      node.value = VALUE_FILL
      node.left = node
      node.right = EOL
      node
    end

    private EOL_ONLY_TREE = begin
      tree = Tree.new
      tree.fill(12, 0, FILL)
      tree.fill(12, 1, EOL)
      tree
    end

    private BLACK_RUN_TREE = begin
      tree = Tree.new
      BLACK_CODES.each_with_index do |codes, i|
        codes.each_with_index do |code, j|
          tree.fill(i + 2, code, BLACK_RUN_LENGTHS[i][j])
        end
      end
      tree.fill(12, 0, FILL)
      tree.fill(12, 1, EOL)
      tree
    end

    private WHITE_RUN_TREE = begin
      tree = Tree.new
      WHITE_CODES.each_with_index do |codes, i|
        codes.each_with_index do |code, j|
          tree.fill(i + 4, code, WHITE_RUN_LENGTHS[i][j])
        end
      end
      tree.fill(12, 0, FILL)
      tree.fill(12, 1, EOL)
      tree
    end

    private CODE_TREE = begin
      tree = Tree.new
      tree.fill(4, 1, VALUE_PASSMODE) # pass mode
      tree.fill(3, 1, VALUE_HMODE)    # H mode
      tree.fill(1, 1, 0)              # V(0)
      tree.fill(3, 3, 1)              # V_R(1)
      tree.fill(6, 3, 2)              # V_R(2)
      tree.fill(7, 3, 3)              # V_R(3)
      tree.fill(3, 2, -1)             # V_L(1)
      tree.fill(6, 2, -2)             # V_L(2)
      tree.fill(7, 2, -3)             # V_L(3)
      tree
    end
  end
end
