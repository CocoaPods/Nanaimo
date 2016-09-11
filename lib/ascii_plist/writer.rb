module AsciiPlist
  class Writer
    UTF8 = "// !$*UTF8*$!\n".freeze

    def initialize(plist, pretty = true, output = ::String.new)
      @plist = plist
      @pretty = pretty
      @output = output
      @indent = 0
    end

    def write
      write_utf8
      write_object(@plist.root_object)
      output << "\n"
    end

    attr_reader :indent, :pretty, :output
    private :indent, :pretty, :output

    private

    def write_utf8
      output << UTF8
    end

    def write_object(object)
      case object
      when Array, ::Array
        write_array(object)
      when Dictionary, ::Hash
        write_dictionary(object)
      when /[^\w\.\/]/, QuotedString, ""
        write_quoted_string(object)
      when String, ::String
        write_string(object)
      when Data
        write_data(object)
      else
        raise "Cannot write #{object} to an ascii plist"
      end
      write_annotation(object, output) if pretty
      output
    end

    def write_string(object)
      output << value_for(object).to_s
    end

    def write_quoted_string(object)
      output << '"' << StringHelper.quotify_string(value_for(object)) << '"'
    end

    def write_data(object)
      raise "write_data unimplemented"
    end

    def write_array(object)
      write_array_start
      value = value_for(object)
      last_index = value.size - 1
      value.each_with_index do |v, index|
        write_array_element(v, index == last_index)
      end
      write_array_end
    end

    def write_array_start
      output << "(\n"
      indent = push_indent!
    end

    def write_array_end
      indent = pop_indent!
      write_indent
      output << ")"
    end

    def write_array_element(object, is_last_element)
      write_indent
      write_object(object)
      output << ',' unless is_last_element
      output << "\n"
    end

    def write_dictionary(object)
      write_dictionary_start
      value = value_for(object)
      value.each do |key, val|
        write_dictionary_key_value_pair(key, val)
      end
      write_dictionary_end
    end

    def write_dictionary_start
      output << "{\n"
      indent = push_indent!
    end

    def write_dictionary_end
      indent = pop_indent!
      write_indent
      output << '}'
    end

    def write_dictionary_key_value_pair(key, value)
      write_indent
      write_object(key)
      output << ' = '
      write_object(value)
      output << ";"
      output << "\n"
    end

    def write_annotation(object, output)
      return output unless object.is_a?(AsciiPlist::Object)
      annotation = object.annotation
      return output unless annotation && !annotation.empty?
      output << " /*#{annotation}*/"
    end

    def value_for(object)
      if object.is_a?(AsciiPlist::Object)
        object.value
      else
        object
      end
    end

    def push_indent!
      @indent += 1
    end

    def pop_indent!
      @indent -= 1
      if @indent < 0
        @indent = 0
      end
    end

    def write_indent
      output << "\t" * indent
    end
  end
end
