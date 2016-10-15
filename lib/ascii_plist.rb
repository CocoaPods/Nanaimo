require 'ascii_plist/version'

module AsciiPlist
  class Error < StandardError; end

  require 'ascii_plist/object'
  require 'ascii_plist/plist'
  require 'ascii_plist/reader'
  require 'ascii_plist/unicode'
  require 'ascii_plist/writer'
  require 'ascii_plist/xcode_project_writer'
end
