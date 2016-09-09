module AsciiPlist
  class StringHelper
    def self.ordinal(character)
      character.ord
    end

    def self.special_whitespace?(character)
      ord = ordinal(character)
      (ord >= 9) && (ord <= 13) # tab, newline, vt, form feed, carriage return
    end

    def self.unicode_seperator?(character)
      ord = ordinal(character)
      (ord == 8232) || (ord == 8233)
    end

    def self.regular_whitespace?(character)
      ord = ordinal(character)
      ord == 32 || unicode_seperator?(character)
    end

    def self.whitespace?(character)
      regular_whitespace?(character) || special_whitespace?(character)
    end

    def self.end_of_line?(character)
      new_line?(character) || unicode_seperator?(character)
    end

    def self.new_line?(character)
      ord = ordinal(character)
      (ord == 13) || (ord == 10)
    end

    # Credit to Samantha Marshall
    # Taken from https://github.com/samdmarshall/pbPlist/blob/346c29f91f913d35d0e24f6722ec19edb24e5707/pbPlist/StrParse.py#L197
    # Licensed under https://raw.githubusercontent.com/samdmarshall/pbPlist/blob/346c29f91f913d35d0e24f6722ec19edb24e5707/LICENSE
    #
    # Originally from: http://www.opensource.apple.com/source/CF/CF-744.19/CFOldStylePList.c See `getSlashedChar()`
    def self.unquotify_string(string)
      formatted_string = ::String.new
      extracted_string = string
      string_length = string.size
      all_cases = ["0", "1", "2", "3", "4", "5", "6", "7", "a", "b", "f", "n", "r", "t", "v", "\n", "U"]
      index = 0
      while index < string_length
        if escape_index = extracted_string.index("\\", index)
          formatted_string << extracted_string[index..escape_index-1] unless index == escape_index
          index = escape_index + 1
          next_char = extracted_string[index]
          if all_cases.include?(next_char)
            index += 1
            if next_char =="'a"
              formatted_string << "\a"
            elsif next_char == "b"
              formatted_string << "\b"
            elsif next_char == "f"
              formatted_string << "\f"
            elsif next_char == "n"
              formatted_string << "\n"
            elsif next_char == "r"
              formatted_string << "\r"
            elsif next_char == "t"
              formatted_string << "\t"
            elsif next_char == "v"
              formatted_string << "\v"
            elsif next_char == "\n"
              formatted_string << "\n"
            elsif next_char == "U"
              starting_index = index
              unicode_numbers = extracted_string[starting_index, 4]
              index += 4
              formatted_string << [unicode_numbers.to_i].pack('U')
            elsif octal_number?(next_char) # https://twitter.com/Catfish_Man/status/658014170055507968
              raise "octal numbers suck"
            else
              raise "didnt handle #{next_char} which is in all_cases"
            end
          else
            index += 1
            formatted_string << next_char
          end
        else
          formatted_string << extracted_string[index..-1]
          index = string_length
        end
      end
      formatted_string
    end

    def self.read_singleline_comment(contents, start_index)
      index = start_index
      end_index = contents.length
      index += 1 while index < end_index && !end_of_line?(contents[index])
      annotation = contents[start_index..index-1]

      [index, annotation]
    end

    def self.eat_whitespace(contents, index)
      si = index
      end_index = contents.length
      index += 1 while index < end_index && whitespace?(contents[index])
      index
    end

    def self.read_multiline_comment(contents, start_index)
      index = start_index
      unless contents[start_index..-1] =~ /\A(?:.+?)(?=\*\/)/m
        raise "#{contents[start_index..-1].inspect} failed to terminate multiline comment"
      end
      annotation = $&
      index += annotation.size + 2

      [index, annotation]
    end

    def self.index_of_next_non_space(contents, current_index)
      index = current_index
      length = contents.length
      annotation = ''
      loop do
        break unless index < length
        current_character = contents[index]
        # Eat Whitespace
        if whitespace?(current_character)
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

        # Eat Whitespace
        if whitespace?(current_character)
          index += 1
          next
        end

        break
      end
      return index, annotation
    end
  end
end
