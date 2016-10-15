require 'ascii_plist/version'

# A native Ruby implementation of ASCII plist parsing and serialization.
#
module AsciiPlist
  class Error < StandardError; end

  DEBUG = !ENV['ASCII_PLIST_DEBUG'].nil?
  private_constant :DEBUG
  def self.debug
    return unless DEBUG
    warn yield
  end

  require 'ascii_plist/object'
  require 'ascii_plist/plist'
  require 'ascii_plist/reader'
  require 'ascii_plist/unicode'
  require 'ascii_plist/writer'
  require 'ascii_plist/xcode_project_writer'
end
