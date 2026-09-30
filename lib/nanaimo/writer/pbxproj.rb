# frozen_string_literal: true

module Nanaimo
  class Writer
    # Transforms native ruby objects or Plist objects into their ASCII Plist
    # string representation, formatted as Xcode writes Xcode projects.
    #
    class PBXProjWriter < Writer
      ISA = String.new('isa', '')
      private_constant :ISA

      def initialize(plist, **args)
        super(plist, **args)
        @objects_section = false
        @known_isa_value = nil
        @known_isa = nil
      end

      private

      def write_dictionary(object)
        n = @newlines
        value = value_for(object)
        isa = @known_isa_value.equal?(value) ? @known_isa : isa_for(value)
        @newlines = false if flat_isa?(isa)
        if @objects_section
          @objects_section = false
          write_objects_section(value)
        else
          write_dictionary_start
          sorted_keys(value, key_can_be_isa: true).each do |k|
            write_dictionary_key_value_pair(k, value[k])
          end
          write_dictionary_end
        end
      ensure
        @newlines = n
      end

      def write_objects_section(objects)
        write_dictionary_start
        keys_by_isa = {}
        objects.each do |k, v|
          isa = isa_for(v)
          (keys_by_isa[isa] ||= []) << k
        end
        keys_by_isa.each do |isa, keys|
          write_newline
          output << '/* Begin ' << isa.to_s << ' section */'
          write_newline
          sort_keys!(keys).each do |k|
            v = objects[k]
            @known_isa_value = value_for(v)
            @known_isa = isa
            write_dictionary_key_value_pair(k, v)
          end
          @known_isa_value = @known_isa = nil
          output << '/* End ' << isa.to_s << ' section */'
          write_newline
        end
        write_dictionary_end
      end

      def write_dictionary_key_value_pair(k, v)
        # since the objects section is always at the top-level,
        # we can avoid checking if we're starting the 'objects'
        # section if we're further "indented" (aka deeper) in the project
        @objects_section = true if @indent == 1 && value_for(k) == 'objects'

        super
      end

      # Sorts keys by their string value, with `isa` first when
      # `key_can_be_isa` is set.
      def sorted_keys(hash, key_can_be_isa: true)
        keys = sort_keys!(hash.keys)
        if key_can_be_isa && (index = keys.index('isa')) && index.positive?
          keys.unshift(keys.delete_at(index))
        end
        keys
      end

      def sort_keys!(keys)
        # Plain strings sort fastest natively; Nanaimo::Object#<=> would give
        # the same order, but through a Ruby-level comparison.
        if keys.first.is_a?(Nanaimo::Object)
          keys.sort_by! { |k| k.is_a?(Nanaimo::Object) ? k.value : k }
        else
          keys.sort!
        end
      end

      def isa_for(dictionary)
        dictionary = value_for(dictionary)
        return unless dictionary.is_a?(Hash)
        if isa = dictionary['isa']
          value_for(isa)
        elsif isa = dictionary[ISA]
          value_for(isa)
        end
      end

      def flat_isa?(isa)
        case isa
        when 'PBXBuildFile', 'PBXFileReference'
          true
        else
          false
        end
      end
    end
  end
end
