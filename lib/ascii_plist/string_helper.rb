module AsciiPlist
  class StringHelper
    def self.ordinal(character)
      character.unpack('U')[0]
    end

    def self.is_special_whitespace?(character)
      ord = ordinal(character)
      (ord >= 9) && (ord <= 13) # tab, newline, vt, form feed, carriage return
    end

    def self.is_unicode_seperator?(character)
      ord = ordinal(character)
      (ord == 8232) || (ord == 8233)
    end

    def self.is_regular_whitespace?(character)
      ord = ordinal(character)
      ord == 32 || is_unicode_seperator?(character) 
    end

    def self.is_whitespace?(character)
      is_regular_whitespace?(character) || is_special_whitespace?(character)
    end

    def self.is_end_of_line?(character)
      is_new_line?(character) || is_unicode_seperator?(character)
    end

    def self.is_new_line?(character)
      ord = ordinal(character)
      (ord == 13) || (ord == 10)  
    end

    def self.read_singleline_comment(contents, start_index)
      index = start_index
      end_index = contents.length
      annotation = ''
      while index < end_index
        current_character = contents[index]
        if !is_end_of_line?(current_character)
          annotation += current_character
          index += 1
        else
          break
        end
      end

      return index, annotation
    end

    def self.read_multiline_comment(contents, start_index)
      index = start_index
      end_index = contents.length
      annotation = ''
      while index < end_index
        current_character = contents[index]
        if current_character == '*' && (index + 1) <= end_index && contents[index + 1] == '/'
          index += 2
          break
        else
          annotation += current_character
          index += 1
        end
      end

      return index, annotation
    end

    def self.index_of_next_non_space(contents, current_index)
      index = current_index
      length = contents.length
      annotation = ''
      while index < length
        current_character = contents[index]
        # Eat Whitespace
        if is_whitespace?(current_character)
          index += 1
          next
        end

        # Comment Detection
        if current_character == '/'
          index += 1

          current_character = contents[index]

          if current_character == '/'
            index += 1
            index, annotation = read_singleline_comment(contents, index)
            next
          elsif current_character == '*'
            index += 1
            index, annotation = read_multiline_comment(contents, index)
            next
          end
        end

        return index, annotation
      end
    end
  end
end
