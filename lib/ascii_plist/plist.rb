module AsciiPlist
  class Plist
    # @return [AsciiPlist::Object] The root level object in the plist.
    #
    attr_accessor :root_object

    # @return [String] The encoding of the plist.
    #
    attr_accessor :file_type
  end
end
