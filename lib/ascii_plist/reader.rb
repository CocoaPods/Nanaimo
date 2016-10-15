# frozen-string-literal: true
module AsciiPlist
  class Reader
    class UnsupportedPlistFormatError < Error
      attr_reader :format
      def initialize(format)
        @format = format
      end

      def to_s
        "#{format} plists are currently unsupported"
      end
    end

    class ParseError < Error
      attr_accessor :location
      attr_accessor :plist_string
    end

    attr_accessor :plist

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

    def self.from_file(file_path)
      new(File.read(file_path))
    end

    def initialize(contents)
      @scanner = StringScanner.new(contents)
    end

    def parse!
      plist_format = ensure_ascii_plist!
      read_string_encoding
      root_object = parse_object

      eat_whitespace!
      raise_parser_error ParseError, "unrecognized characters #{@scanner.rest.inspect} after parsing" unless @scanner.eos?

      AsciiPlist::Plist.new(root_object, plist_format)
    end

    private

    def ensure_ascii_plist!
      self.class.plist_type(@scanner.string).tap do |plist_format|
        raise UnsupportedPlistFormatError(plist_format) unless plist_format == :ascii
      end
    end

    def read_string_encoding
      # TODO
    end

    def parse_object
      _comment = skip_to_non_space_matching_annotations
      start_pos = @scanner.pos
      raise_parser_error ParseError, "Unexpected eos while parsing" if @scanner.eos?
      if @scanner.skip /\{/
        parse_dictionary
      elsif @scanner.skip /\(/
        parse_array
      elsif @scanner.skip /</
        parse_data
      elsif quote = @scanner.scan(/['"]/)
        parse_quotedstring(quote)
      else
        parse_string
      end.tap do |o|
        o.annotation = skip_to_non_space_matching_annotations
        warn "parsed #{o.inspect} from #{start_pos}..#{@scanner.pos}" if ENV["ASCII_PLIST_DEBUG"]
      end
    end

    def parse_string
      eat_whitespace!
      unless match = @scanner.scan(/[\w\/.]+/)
        raise_parser_error ParseError, "not a valid string at index #{@scanner.pos} (char is #{current_character.inspect})"
      end
      AsciiPlist::String.new(match, nil)
    end

    def parse_quotedstring(quote)
      unless string = @scanner.scan(/(?:([^#{quote}\\]|\\.)*)#{quote}/)
        raise_parser_error ParseError, "unterminated quoted string started at #{@scanner.pos}, expected #{quote} but never found it"
      end
      string = Unicode.unquotify_string(string.chomp!(quote))
      AsciiPlist::QuotedString.new(string, nil)
    end

    def parse_array
      objects = []
      while !@scanner.eos?
        eat_whitespace!
        break if @scanner.skip(/\)/)

        objects << parse_object

        eat_whitespace!
        break if @scanner.skip(/\)/)
        unless @scanner.skip(/,/)
          raise_parser_error ParseError, "Array #{objects} missing ',' in between objects"
        end
      end

      AsciiPlist::Array.new(objects, nil)
    end

    def parse_dictionary
      objects = {}
      while !@scanner.eos?
        skip_to_non_space_matching_annotations
        break if @scanner.skip(/}/)

        key = parse_object
        eat_whitespace!
        unless @scanner.skip(/=/)
          raise_parser_error ParseError, "Dictionary missing value after key #{key.inspect} at index #{@scanner.pos}, expected '=' and got #{current_character.inspect}"
        end

        value = parse_object
        objects[key] = value

        eat_whitespace!
        break if @scanner.skip(/}/)
        unless @scanner.skip(/;/)
          raise_parser_error ParseError, "Dictionary (#{objects}) missing ';' after key-value pair (#{key} = #{value}) at index #{@scanner.pos} (got #{current_character})"
        end
      end

      AsciiPlist::Dictionary.new(objects, nil)
    end

    def parse_data
      unless data = @scanner.scan(/[\h ]*>/)
        raise_parser_error ParseError, "Data missing closing '>'"
      end
      data.chomp!('>')
      data.delete!(" ")
      unless data.size % 2 == 0
        @scanner.unscan
        raise_parser_error ParseError, "Data has an uneven number of hex digits"
      end
      data = [data].pack("H*")
      AsciiPlist::Data.new(data, nil)
    end

    def current_character
      @scanner.peek(1)
    end

    def read_singleline_comment
      unless comment = @scanner.scan_until(NEWLINE)
        raise_parser_error ParseError, "failed to terminate single line comment #{@scanner.rest.inspect}"
      end
      comment
    end

    def eat_whitespace!
      @scanner.skip MANY_WHITESPACES
    end

    NEWLINE_CHARACTERS = %W(\x0A \x0D \u2028 \u2029)
    NEWLINE = Regexp.union(*NEWLINE_CHARACTERS)

    WHITESPACE_CHARACTERS = NEWLINE_CHARACTERS + %W(\x09 \x0B \x0C \x20)
    WHITESPACE = Regexp.union(*WHITESPACE_CHARACTERS)

    MANY_WHITESPACES = /#{WHITESPACE}+/

    def read_multiline_comment
      unless annotation = @scanner.scan(/(?:.+?)(?=\*\/)/m)
        raise_parser_error ParseError, "#{@scanner.rest.inspect} failed to terminate multiline comment"
      end
      @scanner.skip(/\*\//)

      annotation
    end

    def skip_to_non_space_matching_annotations
      annotation = ''.freeze
      while !@scanner.eos?
        eat_whitespace!

        # Comment Detection
        if @scanner.skip(/\/\//)
          annotation = read_singleline_comment
          next
        elsif @scanner.skip(/\/\*/)
          annotation = read_multiline_comment
          next
        end

        eat_whitespace!

        break
      end
      annotation
    end

    def location_in(scanner)
      pos = scanner.charpos
      line = scanner.string[0..scanner.charpos].scan(NEWLINE).size + 1
      column = pos - (scanner.string.rindex(NEWLINE, pos - 1) || -1)
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
