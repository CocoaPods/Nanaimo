# frozen-string-literal: true

autoload :StringScanner, 'strscan'

module Nanaimo
  # Transforms plist strings into Plist objects.
  #
  class Reader
    # Raised when attempting to read a plist with an unsupported file format.
    #
    class UnsupportedPlistFormatError < Error
      # @return [Symbol] The unsupported format.
      #
      attr_reader :format

      def initialize(format)
        @format = format
      end

      def to_s
        "#{format} plists are currently unsupported"
      end
    end

    # Raised when parsing fails.
    #
    class ParseError < Error
      # @return [[Integer, Integer]] The (line, column) offset into the plist
      #         where the error occurred
      #
      attr_accessor :location

      # @return [String] The contents of the plist.
      #
      attr_accessor :plist_string

      def to_s
        "[!] #{super}#{context}"
      end

      def context(n = 2)
        line_number, column = location
        line_number -= 1
        lines = plist_string.split(NEWLINE)

        s = line_number.succ.to_s.size
        indent     = "#{' ' * s}#  "
        indicator  = "#{line_number.succ}>  "

        m =  ::String.new("\n")

        m << "#{indent}-------------------------------------------\n"
        m << lines[[line_number - n, 0].max...line_number].map do |l|
          "#{indent}#{l}\n"
        end.join

        line = lines[line_number].to_s
        m << "#{indicator}#{line}\n"

        m << ' ' * indent.size
        m << line[0, column.pred].gsub(/[^\t]/, ' ')
        m << "^\n"

        m << Array(lines[line_number.succ..[lines.count.pred, line_number + n].min]).map do |l|
          l.strip.empty? ? '' : "#{indent}#{l}\n"
        end.join
        m << "#{indent}-------------------------------------------\n"
      end
    end

    # @param plist_contents [String]
    #
    # @return [Symbol] The file format of the plist in the given string.
    #
    def self.plist_type(plist_contents)
      case plist_contents
      when /\Abplist/
        :binary
      when /\A<\?xml/
        :xml
      else
        :ascii
      end
    end

    # @param file_path [String]
    #
    # @return [Plist] A parsed plist from the given file
    #
    def self.from_file(file_path)
      new(File.read(file_path))
    end

    # @param contents [String] The plist to be parsed
    #
    def initialize(contents)
      @scanner = StringScanner.new(contents)
      @string = @scanner.string
      @walk_unquoted_strings = self.class.prefer_byte_walking?
    end

    # @return [Boolean] Whether walking bytes in Ruby beats a regexp engine
    #         call for short tokens. True under YJIT and on non-CRuby
    #         implementations; ZJIT and the interpreter favor the regexp.
    #
    # @!visibility private
    #
    def self.prefer_byte_walking?
      return true unless defined?(RubyVM) # JRuby, TruffleRuby
      defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? true : false
    end

    # Parses the contents of the plist
    #
    # @return [Plist] The parsed Plist object.
    #
    def parse!
      plist_format = ensure_ascii_plist!
      read_string_encoding
      root_object = parse_object

      eat_whitespace!
      raise_parser_error ParseError, 'Found additional characters after parsing the root plist object' unless @scanner.eos?

      Nanaimo::Plist.new(root_object, plist_format)
    end

    private

    def ensure_ascii_plist!
      self.class.plist_type(@scanner.string).tap do |plist_format|
        raise UnsupportedPlistFormatError, plist_format unless plist_format == :ascii
      end
    end

    def read_string_encoding
      # TODO
    end

    UNQUOTED_STRING = %r{[\w_$/:.-]+}
    UNQUOTED_STRING_BYTES = ::Array.new(256) { |b| !(UNQUOTED_STRING =~ b.chr).nil? }.freeze
    DOUBLE_QUOTED_BODY = /[^"\\]*(?:\\.[^"\\]*)*/
    SINGLE_QUOTED_BODY = /[^'\\]*(?:\\.[^'\\]*)*/
    DATA_BODY = /[\h ]*>/
    MULTILINE_COMMENT_BODY = %r{(?m:.)[^*]*(?:\*(?!/)[^*]*)*(?=\*/)}
    private_constant :UNQUOTED_STRING, :UNQUOTED_STRING_BYTES, :DOUBLE_QUOTED_BODY, :SINGLE_QUOTED_BODY, :DATA_BODY, :MULTILINE_COMMENT_BODY

    def parse_object(already_parsed_comment: false)
      skip_to_non_space_matching_annotations unless already_parsed_comment
      start_pos = @scanner.pos
      raise_parser_error ParseError, 'Unexpected end of string while parsing' if @scanner.eos?
      o = case @string.getbyte(start_pos)
          when 0x7B # '{'
            @scanner.pos = start_pos + 1
            parse_dictionary
          when 0x28 # '('
            @scanner.pos = start_pos + 1
            parse_array
          when 0x3C # '<'
            @scanner.pos = start_pos + 1
            parse_data
          when 0x22 # '"'
            @scanner.pos = start_pos + 1
            parse_quotedstring('"', DOUBLE_QUOTED_BODY)
          when 0x27 # "'"
            @scanner.pos = start_pos + 1
            parse_quotedstring("'", SINGLE_QUOTED_BODY)
          else
            parse_string
          end
      o.annotation = skip_to_non_space_matching_annotations
      Nanaimo.debug { "parsed #{o.inspect} from #{start_pos}..#{@scanner.pos}" } if DEBUG
      o
    end

    def parse_string
      if @walk_unquoted_strings
        start_pos = pos = @scanner.pos
        pos += 1 while (byte = @string.getbyte(pos)) && UNQUOTED_STRING_BYTES[byte]
        match = @string.byteslice(start_pos, pos - start_pos) unless pos == start_pos
        @scanner.pos = pos
      else
        match = @scanner.scan(UNQUOTED_STRING)
      end
      raise_parser_error ParseError, "Invalid character #{current_character.inspect} in unquoted string" unless match
      Nanaimo::String.new(match, nil)
    end

    def parse_quotedstring(quote, body)
      start_pos = @scanner.pos
      string = @scanner.scan(body)
      if peek_byte == quote.ord
        @scanner.pos += 1
      else
        @scanner.pos = start_pos
        raise_parser_error ParseError, "Unterminated quoted string, expected #{quote} but never found it"
      end
      string = if string.include?('\\')
                 Unicode.unquotify_string(string)
               elsif string.ascii_only?
                 string.force_encoding(Encoding::BINARY)
               else
                 string
               end
      Nanaimo::QuotedString.new(string, nil)
    end

    def parse_array
      objects = []
      until @scanner.eos?
        skip_to_non_space_matching_annotations
        if peek_byte == 0x29 # ')'
          @scanner.pos += 1
          break
        end

        objects << parse_object(already_parsed_comment: true)

        case peek_byte
        when 0x29 # ')'
          @scanner.pos += 1
          break
        when 0x2C # ','
          @scanner.pos += 1
        else
          raise_parser_error ParseError, "Array missing ',' in between objects"
        end
      end

      Nanaimo::Array.new(objects, nil)
    end

    def parse_dictionary
      objects = {}
      until @scanner.eos?
        skip_to_non_space_matching_annotations
        if peek_byte == 0x7D # '}'
          @scanner.pos += 1
          break
        end

        key = parse_object(already_parsed_comment: true)
        unless peek_byte == 0x3D # '='
          raise_parser_error ParseError, "Dictionary missing value for key #{key.as_ruby.inspect}, expected '=' and found #{current_character.inspect}"
        end
        @scanner.pos += 1

        value = parse_object
        objects[key] = value

        case peek_byte
        when 0x7D # '}'
          @scanner.pos += 1
          break
        when 0x3B # ';'
          @scanner.pos += 1
        else
          raise_parser_error ParseError, "Dictionary missing ';' after key-value pair for #{key.as_ruby.inspect}, found #{current_character.inspect}"
        end
      end

      Nanaimo::Dictionary.new(objects, nil)
    end

    def parse_data
      unless data = @scanner.scan(DATA_BODY)
        raise_parser_error ParseError, "Data missing closing '>'"
      end
      data.chomp!('>')
      data.delete!(' ')
      unless data.size.even?
        @scanner.unscan
        raise_parser_error ParseError, 'Data has an uneven number of hex digits'
      end
      data = [data].pack('H*')
      Nanaimo::Data.new(data, nil)
    end

    def current_character
      @scanner.peek(1)
    end

    if StringScanner.method_defined?(:peek_byte)
      def peek_byte
        @scanner.peek_byte
      end
    else
      def peek_byte
        @string.getbyte(@scanner.pos)
      end
    end

    def read_singleline_comment
      unless comment = @scanner.scan_until(NEWLINE)
        raise_parser_error ParseError, 'Failed to terminate single line comment'
      end
      comment
    end

    def eat_whitespace!
      @scanner.skip(MANY_WHITESPACES)
    end

    NEWLINE_CHARACTERS = %W(\x0A \x0D \u2028 \u2029).freeze
    NEWLINE = Regexp.union(*NEWLINE_CHARACTERS)

    WHITESPACE_CHARACTERS = NEWLINE_CHARACTERS + %W(\x09 \x0B \x0C \x20)
    WHITESPACE = Regexp.union(*WHITESPACE_CHARACTERS)

    MANY_WHITESPACES = /#{WHITESPACE}+/

    def read_multiline_comment
      unless annotation = @scanner.scan(MULTILINE_COMMENT_BODY)
        raise_parser_error ParseError, 'Failed to terminate multiline comment'
      end
      @scanner.pos += 2

      annotation
    end

    def skip_to_non_space_matching_annotations
      annotation = ''.freeze
      scanner = @scanner
      string = @string
      pos = scanner.pos
      while true # rubocop:disable Style/InfiniteLoop
        case string.getbyte(pos)
        when 0x20, 0x09, 0x0A, 0x0B, 0x0C, 0x0D
          # Short ASCII whitespace runs are cheaper to walk byte-by-byte than
          # to hand to the regexp engine.
          pos += 1
          while (byte = string.getbyte(pos)) && (byte == 0x20 || (byte <= 0x0D && byte >= 0x09))
            pos += 1
          end
        when 0xE2 # lead byte of U+2028 and U+2029
          scanner.pos = pos
          break unless skipped = scanner.skip(MANY_WHITESPACES)
          pos += skipped
        when 0x2F # '/'
          case string.getbyte(pos + 1)
          when 0x2F # '/'
            scanner.pos = pos + 2
            annotation = read_singleline_comment
          when 0x2A # '*'
            scanner.pos = pos + 2
            annotation = read_multiline_comment
          else
            break
          end
          pos = scanner.pos
        else
          break
        end
      end
      scanner.pos = pos
      annotation
    end

    def location_in(scanner)
      pos = scanner.charpos
      line = scanner.string[0..scanner.charpos].scan(NEWLINE).size + 1
      column = pos - (scanner.string.rindex(NEWLINE, pos - 1) || -1)
      column = [1, column].max
      [line, column]
    end

    def raise_parser_error(klass, message)
      exception = klass.new(message).tap do |error|
        error.location = location_in(@scanner)
        error.plist_string = @scanner.string
      end
      raise(exception)
    end
  end
end
