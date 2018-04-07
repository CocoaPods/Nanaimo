# frozen_string_literal: true

module Nanaimo
  class Writer
    # Transforms native ruby objects or Plist objects into their ASCII Plist
    # string representation, formatted as Xcode writes Xcode projects.
    #
    class PBXProjWriter < Writer
      ISA = String.new('isa', '')
      private_constant :ISA

      def initialize(*)
        super
        @objects_section = false
      end

      private

      def write_dictionary(object)
        n = newlines
        @newlines = false if flat_dictionary?(object)
        return super(sort_dictionary(object)) unless @objects_section
        @objects_section = false
        write_dictionary_start
        value = value_for(object)
        objects_by_isa = value.group_by { |_k, v| isa_for(v) }
        objects_by_isa.each do |isa, kvs|
          write_newline
          output << "/* Begin #{isa} section */"
          write_newline
          sort_dictionary(kvs, key_can_be_isa: false).each do |k, v|
            write_dictionary_key_value_pair(k, v)
          end
          output << "/* End #{isa} section */"
          write_newline
        end
        write_dictionary_end
      ensure
        @newlines = n
      end

      def write_dictionary_key_value_pair(k, v)
        @objects_section = true if value_for(k) == 'objects'
        super
      end

      def sort_dictionary(dictionary, key_can_be_isa: true)
        hash = value_for(dictionary)
        hash.sort_by do |k, _v|
          k = value_for(k)
          if key_can_be_isa
            k == 'isa' ? '' : k
          else
            k
          end
        end
      end

      def isa_for(dictionary)
        dictionary = value_for(dictionary)
        return unless dictionary.is_a?(Hash)
        isa = dictionary.values_at('isa', ISA).map(&method(:value_for)).compact.first
        isa && value_for(isa)
      end

      def flat_dictionary?(dictionary)
        case isa_for(dictionary)
        when 'PBXBuildFile', 'PBXFileReference'
          true
        else
          false
        end
      end
    end
  end
end
