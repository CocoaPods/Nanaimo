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

    def parse_object
      @index, annotation = StringHelper.index_of_next_non_space(@contents, @index)
      return if @index == @contents.length
      starting_character = @contents[@index]
      if starting_character == '{'
        parse_dictionary
      elsif starting_character == '('
        parse_array
      elsif starting_character == '<'
        raise 'Data is currently unsupported'
      elsif starting_character == "'" || '"'
        parse_quotedstring
      else
        parse_string
      end
    end

    def parse_string
    end

    def parse_quotedstring
    end

    def parse_array
      objects = []
      @index += 1
      start_index = @index

      AsciiPlist::Array.new(objects, 'array', nil)
    end

    def parse_dictionary
    end

    def parse_data
    end
  end
end
