module AsciiPlist
  class Object
    attr_accessor :value, :annotation

    def initialize(value, annotation)
      self.value = value
      self.annotation = annotation

      raise 'Item cannot be initialize with a nil value' if value.nil?
    end

    def ==(object)
      value == object.value && annotation == object.annotation
    end
    alias eql? ==

    def hash
      value.hash
    end

    def <=>(object)
      value <=> object.value
    end

    def to_s
      format('<%s %s>', self.class, self.value)
    end

    def as_ruby
      raise "unimplemented"
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
  end

  class Array < Object
    def as_ruby
      value.map(&:as_ruby)
    end
  end

  class Dictionary < Object
    def as_ruby
      Hash[value.map {|k, v| [k.as_ruby, v.as_ruby] }]
    end
  end
end
