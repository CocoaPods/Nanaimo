module AsciiPlist
  class Object
    attr_accessor :value, :annotation

    def initialize(value, annotation)
      self.value = value
      self.annotation = annotation

      raise 'Item cannot be initialize with a nil value' if value.nil?
    end

    def ==(other)
      return unless other
      if other.is_a?(self.class)
        other.value == value && annotation == other.annotation
      elsif other.is_a?(value.class)
        other == value
      end
    end
    alias eql? ==

    def hash
      value.hash
    end

    def <=>(other)
      other_value = if other.is_a?(Object)
                      other.value
                    elsif other.is_a?(value.class)
                      other
                    end
      return unless other_value

      value <=> other_value
    end

    def to_s
      format('<%s %s>', self.class, value)
    end

    def as_ruby
      raise 'unimplemented'
    end
  end

  class String < Object
    def as_ruby
      value
    end
  end

  class QuotedString < Object
    def as_ruby
      value
    end
  end

  class Data < Object
    def initialize(value, annotation)
      value &&= value.force_encoding(Encoding::BINARY)
      super(value, annotation)
    end

    def as_ruby
      value
    end
  end

  class Array < Object
    def as_ruby
      value.map(&:as_ruby)
    end
  end

  class Dictionary < Object
    def as_ruby
      Hash[value.map { |k, v| [k.as_ruby, v.as_ruby] }]
    end
  end
end
