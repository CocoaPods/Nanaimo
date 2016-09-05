module AsciiPlist
  class Object
    attr_accessor :value, :type_name, :annotation

    def initialize(value, type_name, annotation)
      self.value = value
      self.type_name = type_name
      self.annotation = annotation

      raise 'Item cannot be initialize with a nil value' if value.nil?
    end

    def write(indent_level, pretty)
      raise 'Norbert::Item subclasses are required to subclass write'
    end

    private

    def write_annotation
      return '' unless annotation && annotation.length > 0
      " /*#{annotation}*/"
    end

    def push_indent(level)
      level + 1
    end

    def pop_indent(level)
      max(0, level - 1)
    end
  end

  class String < Object
    def write(indent_level, pretty)
      output = value
      output += write_annotation if pretty

      return output, indent_level
    end 
  end

  class QuotedString < Object
    def write(indent_level, pretty)
      output = "\"#{value}\""
      output += write_annotation if pretty

      return output, indent_level
    end 
  end

  class Data < Object
  end

  class Array < Object
    def write(indent_level, pretty)
      output = "(\n"
      last_index = value.length - 1
      value.each_with_index do |v, index|
        val, indent_level = v.write(indent_level, pretty)
        output += val
        output += ',' if index < last_index
        output += "\n"
      end
      output += ")"

      return output, indent_level
    end
  end

  class Dictionary < Object
  end
end
