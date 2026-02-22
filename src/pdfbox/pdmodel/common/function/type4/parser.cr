# Parser for PDF Type 4 functions. This implements a small subset of the PostScript
# language but is no full PostScript interpreter.
module Pdfbox::Pdmodel::Common::Function::Type4
  module Parser
    # Used to indicate the parsers current state.
    enum State
      Newline
      Whitespace
      Comment
      Token
    end

    # This interface defines all possible syntactic elements of a Type 4 function.
    # It is called by the parser as the function is interpreted.
    module SyntaxHandler
      # Indicates that a new line starts.
      # @param text the new line character (CR, LF, CR/LF or FF)
      abstract def new_line(text : String) : Nil

      # Called when whitespace characters are encountered.
      # @param text the whitespace text
      abstract def whitespace(text : String) : Nil

      # Called when a token is encountered. No distinction between operators and values
      # is done here.
      # @param text the token text
      abstract def token(text : String) : Nil

      # Called for a comment.
      # @param text the comment
      abstract def comment(text : String) : Nil
    end

    # Abstract base class for a SyntaxHandler.
    abstract class AbstractSyntaxHandler
      include SyntaxHandler

      def comment(text : String) : Nil
        # nop
      end

      def new_line(text : String) : Nil
        # nop
      end

      def whitespace(text : String) : Nil
        # nop
      end
    end

    # Parses a Type 4 function and sends the syntactic elements to the given
    # syntax handler.
    def self.parse(input : String, handler : SyntaxHandler) : Nil
      Tokenizer.new(input, handler).tokenize
    end

    # Tokenizer for Type 4 functions.
    private class Tokenizer
      NUL   = '\u0000' # NUL
      EOT   = '\u0004' # END OF TRANSMISSION
      TAB   = '\u0009' # TAB CHARACTER
      FF    = '\u000C' # FORM FEED
      CR    = '\r'     # CARRIAGE RETURN
      LF    = '\n'     # LINE FEED
      SPACE = '\u0020' # SPACE

      @input : String
      @index = 0
      @handler : SyntaxHandler
      @state : State = State::Whitespace
      @buffer = String::Builder.new

      def initialize(@input, @handler)
      end

      private def has_more? : Bool
        @index < @input.size
      end

      private def current_char : Char
        @input[@index]
      end

      private def next_char : Char
        @index += 1
        if !has_more?
          EOT
        else
          current_char
        end
      end

      private def peek : Char
        if @index < @input.size - 1
          @input[@index + 1]
        else
          EOT
        end
      end

      private def next_state : State
        ch = current_char
        case ch
        when CR, LF, FF
          @state = State::Newline
        when NUL, TAB, SPACE
          @state = State::Whitespace
        when '%'
          @state = State::Comment
        else
          @state = State::Token
        end
        @state
      end

      def tokenize : Nil
        while has_more?
          @buffer = String::Builder.new
          next_state
          case @state
          when State::Newline
            scan_new_line
          when State::Whitespace
            scan_whitespace
          when State::Comment
            scan_comment
          else
            scan_token
          end
        end
      end

      private def scan_new_line : Nil
        @state = State::Newline
        ch = current_char
        @buffer << ch
        if ch == CR && peek == LF
          # CRLF is treated as one newline
          @buffer << next_char
        end
        @handler.new_line(@buffer.to_s)
        next_char
      end

      private def scan_whitespace : Nil
        @state = State::Whitespace
        @buffer << current_char
        while has_more?
          ch = next_char
          case ch
          when NUL, TAB, SPACE
            @buffer << ch
          else
            break
          end
        end
        @handler.whitespace(@buffer.to_s)
      end

      private def scan_comment : Nil
        @state = State::Comment
        @buffer << current_char
        while has_more?
          ch = next_char
          case ch
          when CR, LF, FF
            break
          else
            @buffer << ch
          end
        end
        # EOF reached
        @handler.comment(@buffer.to_s)
      end

      private def scan_token : Nil
        @state = State::Token
        ch = current_char
        @buffer << ch
        case ch
        when '{', '}'
          @handler.token(@buffer.to_s)
          next_char
          return
        else
          # continue
        end

        while has_more?
          ch = next_char
          case ch
          when NUL, TAB, SPACE, CR, LF, FF, EOT, '{', '}'
            break
          else
            @buffer << ch
          end
        end
        # EOF reached
        @handler.token(@buffer.to_s)
      end
    end
  end
end
