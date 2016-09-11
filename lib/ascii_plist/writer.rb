module AsciiPlist
  class Writer
    UTF8 = "// !$*UTF8*$!\n".freeze

    def initialize(plist)
      @plist = plist
    end

    def write(pretty = true, output = ::String.new)
      output << UTF8
      write_object(@plist.root_object, 0, pretty, output) << "\n"
    end

    private

    def write_object(object, indent, pretty, output)
      case object
      when Array, ::Array
        write_array(object, indent, pretty, output)
      when Dictionary, ::Hash
        write_dictionary(object, indent, pretty, output)
      when /[^\w\.\/]/, QuotedString, ""
        write_quoted_string(object, indent, pretty, output)
      when String, ::String
        write_string(object, indent, pretty, output)
      when Data
        write_data(object, indent, pretty, output)
      else
        raise "Cannot write #{object} to an ascii plist"
      end
      write_annotation(object, output) if pretty
      output
    end

    def write_string(object, indent, pretty, output)
      output << value(object).to_s
    end

    def write_quoted_string(object, indent, pretty, output)
      output << '"' << StringHelper.quotify_string(value(object)) << '"'
    end

    def write_data(object, indent, pretty, output)
      raise "write_data unimplemented"
    end

    def write_array(object, indent, pretty, output)
      output << "(\n"
      indent = push_indent(indent)
      value = value(object)
      last_index = value.size - 1
      value.each_with_index do |v, index|
        write_indent(indent, output)
        write_object(v, indent, pretty, output)
        output << ',' unless index == last_index
        output << "\n"
      end
      indent = pop_indent(indent)
      write_indent(indent, output)
      output << ")"
    end

    def write_dictionary(object, indent, pretty, output)
      output << "{\n"
      indent = push_indent(indent)
      value = value(object)
      value.each do |key, val|
        write_indent(indent, output)
        write_object(key, indent, pretty, output)
        output << ' = '
        write_object(value[key], indent, pretty, output)
        output << ";"
        output << "\n"
      end
      indent = pop_indent(indent)
      write_indent(indent, output)
      output << '}'
    end

    def write_annotation(object, output)
      return output unless object.is_a?(AsciiPlist::Object)
      annotation = object.annotation
      return output unless annotation && !annotation.empty?
      output << " /*#{annotation}*/"
    end

    def value(object)
      if object.is_a?(AsciiPlist::Object)
        object.value
      else
        object
      end
    end

    def push_indent(level)
      level + 1
    end

    def pop_indent(level)
      level -= 1
      if level < 0
        return 0
      else
        return level
      end
    end

    def write_indent(level, output)
      output << "\t" * level
    end
  end
end
