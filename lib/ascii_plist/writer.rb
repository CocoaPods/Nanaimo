module AsciiPlist
  class Writer
    def initialize(plist)
      @plist = plist
    end

    def write(pretty = true)
      write_object(@plist.root_object, 0, pretty)
    end

    private

    def write_object(object, indent, pretty, output = ::String.new)
      case object
      when Array
        write_array(object, indent, pretty, output)
      when Dictionary
        write_dictionary(object, indent, pretty, output)
      when String
        write_string(object, indent, pretty, output)
      when QuotedString
        write_quoted_string(object, indent, pretty, output)
      when Data
        write_data(object, indent, pretty, output)
      else
        raise "Cannot write #{object} to an ascii plist"
      end
      write_annotation(object, output) if pretty
      output
    end

    def write_string(object, indent, pretty, output)
      output << object.value
    end

    def write_quoted_string(object, indent, pretty, output)
      output << '"' << object.value.gsub('"', '\\"') << '"'
    end

    def write_data(object, indent, pretty, output)
      raise "write_data unimplemented"
    end

    def write_array(object, indent, pretty, output)
      output << "(\n"
      indent = push_indent(indent)
      last_index = object.value.size - 1
      object.value.each_with_index do |v, index|
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
      keys = object.value.keys.sort
      keys.each_with_index do |key, index|
        write_indent(indent, output)
        write_object(key, indent, pretty, output)
        output << ' = '
        write_object(object.value[key], indent, pretty, output)
        output << ";\n"
      end
      indent = pop_indent(indent)
      write_indent(indent, output)
      output << '}'
    end

    def write_annotation(object, output)
      annotation = object.annotation
      return output unless annotation && !annotation.empty?
      output << " /*#{annotation}*/"
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
