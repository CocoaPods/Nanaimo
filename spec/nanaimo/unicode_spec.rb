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
      '12' => ['12'],
      '129' => ['129'],
      '1h9' => ['1h9'],
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

      it 'decodes every one-digit short octal escape' do
        (0..7).each do |byte|
          expect(described_class.unquotify_string("\\#{byte}")).to eq(byte.chr(Encoding::UTF_8))
        end
      end

      it 'decodes every two-digit short octal escape, including leading zeroes' do
        (0..63).each do |byte|
          expect(described_class.unquotify_string(format('\\%02o', byte))).to eq(byte.chr(Encoding::UTF_8))
        end
      end

      it 'stops short octal escapes at a non-octal character or three digits' do
        expect(described_class.unquotify_string('\\1234\\12x\\1h9\\129')).to eq("S4\nx\u0001h9\n9")
      end

      it 'still rejects octal escapes outside the byte range' do
        %w[\\400 \\777].each do |string|
          expect { described_class.unquotify_string(string) }.to raise_error(described_class::InvalidEscapeSequenceError)
        end
      end

      it 'decodes escaped UTF-16 surrogate pairs as valid UTF-8' do
        decoded = described_class.unquotify_string('\\Ud83d\\UDE00')
        expect(decoded).to eq('😀')
        expect(decoded.valid_encoding?).to be(true)
      end

      it 'combines surrogate pairs at both supplementary Unicode boundaries' do
        expect(described_class.unquotify_string('\\Ud800\\Udc00\\UDBFF\\UDFFF')).to eq("\u{10000}\u{10ffff}")
      end

      it 'preserves text and following Unicode escapes around surrogate pairs' do
        expect(described_class.unquotify_string('a\\Ud83d\\Ude00\\U0042\\Ud801\\Udc00z')).to eq("a😀B\u{10400}z")
      end

      it 'leaves unpaired and non-adjacent surrogate code units unchanged' do
        {
          '\\Ud800' => [0xd800],
          '\\Udc00' => [0xdc00],
          '\\Ud800a\\Udc00' => [0xd800, 0x61, 0xdc00],
          '\\Ud800\\U0041' => [0xd800, 0x41],
          '\\U0041\\Udc00' => [0x41, 0xdc00]
        }.each do |escaped, code_units|
          expect(described_class.unquotify_string(escaped).bytes).to eq(code_units.pack('U*').bytes)
        end
      end

      it 'still rejects malformed Unicode escapes following a high surrogate' do
        %w[\\Ud800\\U01 \\Ud800\\U000G].each do |string|
          expect { described_class.unquotify_string(string) }.to raise_error(described_class::InvalidEscapeSequenceError)
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
