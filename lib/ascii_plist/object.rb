module AsciiPlist
  class Object
    attr_accessor :value, :type_name, :annotation

    def initialize(value, type_name, annotation)
      self.value = value
      self.type_name = type_name
      self.annotation = annotation

      raise 'Item cannot be initialize with a nil value' if value.nil?
    end

    def write(_indent_level, _pretty)
      raise 'Norbert::Item subclasses are required to subclass write'
    end

    def eql?(object)
      type_name == object.type_name && value == object.value && annotation == object.annotation
    end

    def hash
      value.hash
    end

    def <=>(object)
      value <=> object.value
    end

    private

    def write_annotation
      return '' unless annotation && !annotation.empty?
      " /*#{annotation}*/"
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

    def write_indent(level)
      indent = "\t" * level
    end
  end

  class String < Object
    def write(indent_level, pretty)
      output = value
      output += write_annotation if pretty

      [output, indent_level]
    end
  end

  class QuotedString < Object
    def write(indent_level, pretty)
      output = "\"#{value}\""
      output += write_annotation if pretty

      [output, indent_level]
    end
  end

  class Data < Object
  end

  class Array < Object
    def write(indent_level, pretty)
      output = "(\n"
      indent_level = push_indent(indent_level)
      last_index = value.length - 1
      value.each_with_index do |v, index|
        val, indent_level = v.write(indent_level, pretty)
        output += write_indent(indent_level)
        output += val
        output += ',' if index < last_index
        output += "\n"
      end
      indent_level = pop_indent(indent_level)
      output += ')'

      [output, indent_level]
    end
  end

  class Dictionary < Object
    def write(indent_level, pretty)
      output = "{\n"
      indent_level = push_indent(indent_level)
      sorted_keys = value.keys.sort
      last_index = sorted_keys.length - 1
      sorted_keys.each_with_index do |key, _index|
        key_string, indent_level = key.write(indent_level, pretty)
        value_string, indent_level = value[key].write(indent_level, pretty)
        output += write_indent(indent_level)
        output += key_string
        output += ' = '
        output += value_string
        output += ';'
        output += "\n"
      end
      indent_level = pop_indent(indent_level)
      output += write_indent(indent_level)
      output += '}'

      [output, indent_level]
    end
  end
end
