module AsciiPlist
  # A Plist.
  #
  class Plist
    # @return [AsciiPlist::Object] The root level object in the plist.
    #
    attr_accessor :root_object

    # @return [String] The encoding of the plist.
    #
    attr_accessor :file_type

    def initialize(root_object = nil, file_type = nil)
      @root_object = root_object
      @file_type = file_type
    end

    def ==(other)
      return unless other.is_a?(AsciiPlist::Plist)
      file_type == other.file_type && root_object == other.root_object
    end

    def hash
      root_object.hash
    end

    # @return A native Ruby object representation of the plist.
    #
    def as_ruby
      root_object.as_ruby
    end
  end
end
