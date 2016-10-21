require 'spec_helper'

module Nanaimo
  describe Unicode do
    cases = {
      # Unquoted => [Quoted]
      'abc' => ['abc'],
      "\n" => ['\\n'],
      "\xF0\x9F\x98\x82" => ["\xF0\x9F\x98\x82"],
      "\a\b\f\r\n\t\v\n\'\"" => ["\\a\\b\\f\\r\\n\\t\\v\\n\\'\\\""],
      "\u00FD" => ["\u00FD", '\\367'],
      "\u{1f30c}" => ["\u{1f30c}"],
      "\u1111" => ["\u1111", '\\U1111'],
      "\u001e" => ['\\U001e', '\\U001E'],
      '12' => ['12', '\\12'],
      '129' => ['129', '\\129'],
      '1h9' => ['1h9', '\\1h9'],
      "a\nb" => ['a\\nb', "a\\\nb"],
      "\u0000" => ['\\U0000', "\u0000"],
      '5' => ['5', '\\U0035'],
      "\u0007" => ['\\a', '\\U0007']
    }

    describe '.quotify_string' do
      cases.each do |unquoted, all_quoted|
        quoted = all_quoted.first
        it "quotes #{unquoted.inspect} to #{quoted.inspect}" do
          expect(Unicode.quotify_string(unquoted)).to eq(quoted)
        end
      end
    end

    describe '.unquotify_string' do
      cases.each do |unquoted, all_quoted|
        describe "to #{unquoted.inspect}" do
          all_quoted.each do |quoted|
            it "unquotes #{quoted.inspect} to #{unquoted.inspect}" do
              expect(Unicode.unquotify_string(quoted)).to eq(unquoted)
            end
          end
        end
      end

      it 'raises on invalid unicode sequences' do
        %w(\\U01 \\U \\UU \\U000G).each do |string|
          expect { described_class.unquotify_string(string) }
            .to raise_error(described_class::InvalidEscapeSequenceError, "Unicode '\\U' escape sequence terminated without 4 following hex characters")
        end
      end
    end
  end
end
