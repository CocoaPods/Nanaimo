module AsciiPlist
  class Reader
    attr_accessor :plist

    def self.from_file(file_path)
      Reader.new(File.read(file_path))
    end

    def initialize(contents)
      @contents = contents
    end

    def parse!
      plist = AsciiPlist::Plist.new
      ensure_ascii_plist!
      read_string_encoding
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
    end

    def parse_string
    end

    def parse_quotedstring
    end

    def parse_array
    end

    def parse_dictionary
    end

    def parse_data
    end
  end
end
