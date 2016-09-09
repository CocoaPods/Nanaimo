module AsciiPlist
  class Reader
    attr_accessor :plist

    def self.from_file(file_path)
      Reader.new(File.read(file_path))
    end

    def initialize(contents)
      @contents = contents
      @index = 0
    end

    def parse!
      @plist = AsciiPlist::Plist.new
      ensure_ascii_plist!
      read_string_encoding
      plist.root_object = parse_object

      @plist
    end

    private

    def ensure_ascii_plist!
      prefix = @contents[0, 6]
      if prefix == 'bplist'
        plist.file_type = 'binary'
        raise 'Binary plists are currently  unsupported.'
      elsif prefix == '<?xml '
        plist.file_type = 'xml'
        raise 'XML plists are currently unsupported.'
      else
        plist.file_type = 'ascii'
      end
    end

    def read_string_encoding
      # TODO
    end

    def advance_to_next_token
      StringHelper.index_of_next_non_space(@contents, @index)
    end

    def parse_object
      @index, annotation = advance_to_next_token
      i = @index
      return if @index == @contents.length
      starting_character = @contents[@index]
      if starting_character == '{'
        parse_dictionary
      elsif starting_character == '('
        parse_array
      elsif starting_character == '<'
        parse_data
      elsif starting_character =~ /['"]/
        parse_quotedstring
      else
        parse_string
      end.tap do |o|
        warn "parsed #{o.inspect} from #{i}..<#{@index}" if ENV["ASCII_PLIST_DEBUG"]
        o.annotation = annotation
      end
    end

    def parse_string
      unless @contents[@index..-1] =~ /\A([\w\/.]+)/
        raise "not a valid string at index #{@index} (char is #{@contents[@index]})"
      end
      match = $1
      @index += match.size
      AsciiPlist::String.new(match, nil)
    end

    def parse_quotedstring
      quote = @contents[@index]
      @index += 1
      start_index = @index
      length = @contents.length
      while @index < length
        if @contents[@index] == "\\"
          @index += 2
        elsif @contents[@index] == quote
          string = @contents[start_index..@index - 1]
          string = StringHelper.unquotify_string(string)
          @index += 1
          return AsciiPlist::QuotedString.new(string, nil)
        else
          @index += 1
        end
      end
      raise "unterminated quoted string started at #{start_index}, expected #{quote} but never found it"
    end

    def parse_array
      objects = []
      @index += 1
      length = @contents.length
      while @index < length
        @index, _ = advance_to_next_token
        break if @contents[@index] == ")"

        objects << parse_object

        @index, _ = advance_to_next_token
        break if @contents[@index] == "}"
        @index += 1 if @contents[@index] == ","
      end
      @index += 1

      AsciiPlist::Array.new(objects, nil)
    end

    def parse_dictionary
      objects = {}
      @index += 1
      loop do
        @index, _ = advance_to_next_token
        break if @contents[@index] == "}"

        key = parse_object
        @index, _ = advance_to_next_token
        unless @contents[@index] == "="
          raise "Dictionary missing value after key #{key.inspect} at index #{@index}, expected '=' and got #{@contents[@index]}"
        end
        @index += 1

        value = parse_object
        objects[key] = value

        @index, _ = advance_to_next_token
        break if @contents[@index] == "}"
        unless @contents[@index] == ';'
          raise "Dictionary (#{objects}) missing ';' after key-value pair (#{key} = #{value}) at index #{@index} (got #{@contents[@index]})"
        end
        @index += 1
      end
      @index += 1

      AsciiPlist::Dictionary.new(objects, nil)
    end

    def parse_data
      raise "Data is not yet supported"
    end
  end
end
