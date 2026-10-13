# frozen_string_literal: true

require 'spec_helper'

module Nanaimo
  describe Unicode do
    cases = {
      # Unquoted => [Quoted]
      'abc' => ['abc'],
      "\n" => ['\\n'],
      "\xF0\x9F\x98\x82" => ["\xF0\x9F\x98\x82"],
      "\a\b\f\r\n\t\v\n\'\"" => ["\\a\\b\\f\\r\\n\\t\\v\\n'\\\""],
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
      "\u0007" => ['\\a', '\\U0007'],
      '\\\\\\\\' => ['\\\\\\\\\\\\\\\\'],
      'xz' => ['xz', '\x\z']
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

      it 'decodes every three-digit ASCII octal escape to its byte value' do
        (0..127).each do |byte|
          expect(described_class.unquotify_string(format('\\%03o', byte))).to eq(byte.chr(Encoding::UTF_8))
        end
      end

      it 'maps octal escapes starting at 200 through the NeXTSTEP table' do
        expect(described_class.unquotify_string('\\200\\201')).to eq("\u00a0À")
      end

      it 'does not reuse a preceding NeXTSTEP conversion for ASCII octal escapes' do
        expect(described_class.unquotify_string('\\201\\101\\000\\177')).to eq("ÀA\0\u007f")
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
