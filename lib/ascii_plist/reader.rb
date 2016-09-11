# frozen-string-literal: true
module AsciiPlist
  class Reader
    attr_accessor :plist

    def self.from_file(file_path)
      new(File.read(file_path))
    end

    def initialize(contents)
      @scanner = StringScanner.new(contents)
    end

    def parse!
      @plist = AsciiPlist::Plist.new
      ensure_ascii_plist!
      read_string_encoding
      plist.root_object = parse_object

      eat_whitespace!
      raise "unrecognized characters #{@scanner.rest.inspect} after parsing" unless @scanner.eos?

      @plist
    rescue
      warn "error at #{location} #{@scanner.peek(25).inspect}"
      raise
    end

    private

    def ensure_ascii_plist!
      if @scanner.scan /bplist/
        plist.file_type = 'binary'
        raise 'Binary plists are currently  unsupported.'
      elsif @scanner.match? /<\?xml/
        plist.file_type = 'xml'
        raise 'XML plists are currently unsupported.'
      else
        plist.file_type = 'ascii'
      end
    end

    def read_string_encoding
      # TODO
    end

    def parse_object
      _comment = skip_to_non_space_matching_annotations
      start_pos = @scanner.pos
      raise "Unexpected eos while parsing" if @scanner.eos?
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
        raise "not a valid string at index #{@scanner.pos} (char is #{current_character.inspect})"
      end
      AsciiPlist::String.new(match, nil)
    end

    def parse_quotedstring(quote)
      unless string = @scanner.scan(/(?:([^#{quote}\\]|\\.)*)#{quote}/)
        raise "unterminated quoted string started at #{@scanner.pos}, expected #{quote} but never found it"
      end
      string = StringHelper.unquotify_string(string.chomp(quote))
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
          raise "Array #{objects} missing ',' in between objects"
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
          raise "Dictionary missing value after key #{key.inspect} at index #{@scanner.pos}, expected '=' and got #{current_character.inspect}"
        end

        value = parse_object
        objects[key] = value

        eat_whitespace!
        break if @scanner.skip(/}/)
        unless @scanner.skip(/;/)
          raise "Dictionary (#{objects}) missing ';' after key-value pair (#{key} = #{value}) at index #{@scanner.pos} (got #{current_character})"
        end
      end

      AsciiPlist::Dictionary.new(objects, nil)
    end

    def parse_data
      raise "Data is not yet supported"
    end

    def current_character
      @scanner.peek(1)
    end

    def read_singleline_comment
      unless comment = @scanner.scan_until(NEWLINE)
        raise("failed to terminate single line comment #{@scanner.rest.inspect}")
      end
      comment
    end

    def eat_whitespace!
      @scanner.skip MANY_WHITESPACE
    end

    _NEWLINE = %W(\x0A \x0D \u2028 \u2029)
    NEWLINE = Regexp.union(*_NEWLINE)
    _WHITESPACE = _NEWLINE + %W(\x09 \x0B \x0C \x20)
    WHITESPACE = Regexp.union(*_WHITESPACE)
    MANY_WHITESPACE = /#{WHITESPACE}+/

    def read_multiline_comment
      unless annotation = @scanner.scan(/(?:.+?)(?=\*\/)/m)
        raise "#{@scanner.rest.inspect} failed to terminate multiline comment"
      end
      @scanner.skip(/\*\//)

      annotation
    end

    def skip_to_non_space_matching_annotations
      annotation = ''
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

        # Eat Whitespace
        eat_whitespace!

        break
      end
      annotation
    end

    def location
      pos = @scanner.charpos
      line = @scanner.string[0..@scanner.pos].scan(NEWLINE).size + 1
      column = pos - (@scanner.string.rindex(NEWLINE, pos - 1) || -1)
      [line, column]
    end
  end
end
