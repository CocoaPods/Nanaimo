require 'spec_helper'

module Nanaimo
  describe Reader do
    describe 'Arrays' do
      let(:string) { '()' }
      let(:reader) { Reader.new(string) }
      subject { reader.parse! }

      describe 'that are emtpy' do
        it 'should return a plist' do
          expect(subject).to be_a Plist
        end

        it 'should have a Nanaimo::Array as the root_object' do
          expect(subject.root_object).to be_a Nanaimo::Array
        end

        it 'should have no values' do
          expect(subject.root_object.value.count).to eql 0
        end
      end

      describe 'with values' do
        let(:string) { "(\n\tIDENTIFIER,\nANOTHER_IDENTIFIER)" }

        it 'should return a plist' do
          expect(subject).to be_a Plist
        end

        it 'should have a Nanaimo::Array as the root_object' do
          expect(subject.root_object).to be_a Nanaimo::Array
        end

        it 'should have two values' do
          expect(subject.root_object.value.count).to eql 2
        end

        it 'should maintain ordering' do
          expect(subject.root_object.value.map(&:value)).to eql %w(IDENTIFIER ANOTHER_IDENTIFIER)
        end
      end
    end

    describe 'reading annotations' do
      let(:string) { '{a /*annotation*/ = ( b /*another annotation*/ )}' }
      let(:reader) { Reader.new(string) }
      subject { reader.parse!.root_object }

      it 'should parse the annotations' do
        expect(subject).to eq Nanaimo::Dictionary.new({
                                                        Nanaimo::String.new('a', 'annotation') =>
                                                        Nanaimo::Array.new([
                                                                             Nanaimo::String.new('b', 'another annotation')
                                                                           ], '')
                                                      }, '')
      end
    end

    describe 'reading root level dictionaries' do
      let(:string) { '{a = "a";"b" = b;"c" = "c";   d = d;}' }
      let(:reader) { Reader.new(string) }
      subject { reader.parse! }

      it 'should return a plist' do
        expect(subject).to be_a Plist
      end

      it 'should have a Nanaimo::Dictionary as the root_object' do
        expect(subject.root_object).to be_a Nanaimo::Dictionary
      end

      it 'should have four keys' do
        expect(subject.root_object.value.keys.count).to eq 4
      end

      context 'when the dictionary is empty' do
        let(:string) { '{}' }

        it 'parses correctly' do
          expect(subject).to eq Plist.new(Nanaimo::Dictionary.new({}, ''), :ascii)
        end

        context 'and there are newlines' do
          let(:string) { "\t\n\t{\n\t\n}" }

          it 'parses correctly' do
            expect(subject).to eq Plist.new(Nanaimo::Dictionary.new({}, ''), :ascii)
          end
        end
      end
    end

    describe 'unquoted strings' do
      let(:unquoted_string) { 'TEST' }
      let(:reader) { Reader.new("{key = #{unquoted_string}}") }
      subject { reader.parse!.root_object }

      it 'are parsed correctly' do
        expect(subject).to eq Nanaimo::Dictionary.new({ Nanaimo::String.new('key', '') => Nanaimo::String.new('TEST', '') }, '')
      end

      describe 'that start with a `$`' do
        let(:unquoted_string) { '$PROJECT_DIR/mogenerator/mogenerator' }

        it 'are parsed correctly' do
          expect(subject).to eq Nanaimo::Dictionary.new({ Nanaimo::String.new('key', '') => Nanaimo::String.new('$PROJECT_DIR/mogenerator/mogenerator', '') }, '')
        end
      end

      describe 'that contain' do
        valid_characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + %w(_ $ / : . -)
        valid_characters << valid_characters.join('')
        valid_characters.each do |c|
          describe "the valid character `#{c}`" do
            let(:unquoted_string) { c }
            it 'is parsed correctly' do
              expect(subject).to eq Nanaimo::Dictionary.new({ Nanaimo::String.new('key', '') => Nanaimo::String.new(c, '') }, '')
            end
          end
        end
      end
    end

    describe 'quoted strings' do
      let(:quoted_string) { %("\\"${ABC}\\"\\n\\t\\U0CA0_\u0ca0\p\\\\") }
      let(:reader) { Reader.new("{key = #{quoted_string}}") }
      subject { reader.parse!.root_object }

      it 'parses' do
        expect(subject).to eq Nanaimo::Dictionary.new({ Nanaimo::String.new('key', '') => Nanaimo::QuotedString.new(%("${ABC}"\n\tಠ_ಠp\\), '') }, '')
      end
    end

    describe 'data' do
      let(:data) { '<0001 aB AB Cf 99 7 c >' }
      let(:reader) { Reader.new("{key = #{data}}") }
      subject { reader.parse!.root_object }

      it 'parses' do
        expect(subject).to eq Nanaimo::Dictionary.new({ Nanaimo::String.new('key', '') => Nanaimo::Data.new("\x00\x01\xab\xab\xcf\x99\x7c", '') }, '')
      end

      context 'with an odd number of hex digits' do
        let(:data) { '<12 3>' }

        it 'raises an informative error' do
          expect { subject }.to raise_error(Reader::ParseError, <<-E)
[!] Data has an uneven number of hex digits
 #  -------------------------------------------
1>  {key = <12 3>}
            ^
 #  -------------------------------------------
          E
        end
      end
    end

    describe 'parse errors' do
      shared_examples_for 'parse errors' do |name, plist, expected_error|
        it "raises an informative error #{name}" do
          if expected_error.is_a?(::String)
            prefix = expected_error.scan(/^[ \t]*(?=\S)/).min
            expected_error.gsub!(/^#{prefix}/, '')
          end

          expect { Reader.new(plist).parse! }
            .to raise_error(Reader::ParseError) do |e|
              if e.is_a?(Regexp)
                expect(e.to_s).to match(expected_error)
              else
                expect(e.to_s).to eq(expected_error)
              end
            end
        end
      end

      include_examples 'parse errors',
                       'with a dictionary without an `=`',
                       '{ a = ; }',
                       <<-E
          [!] Invalid character ";" in unquoted string
           #  -------------------------------------------
          1>  { a = ; }
                    ^
           #  -------------------------------------------
        E

      include_examples 'parse errors',
                       'with an unterminated array',
                       <<-PLIST,
          (
            a,
            b,
            (
              c
            )
        PLIST
                       <<-E
          [!] Array missing ',' in between objects
           #  -------------------------------------------
           #                c
           #              )
          7>\s\s
              ^
           #  -------------------------------------------
        E

      include_examples 'parse errors',
                       'with an error in the middle of the plist',
                       <<-PLIST,
(
  #{"a,\n" * 1000}
  c,
  d,
  e,,,
  f,
  g,
  #{"z,\n" * 250}
  zz
)
          PLIST
                       <<-E
            [!] Invalid character "," in unquoted string
                #  -------------------------------------------
                #    c,
                #    d,
            1005>    e,,,
                       ^
                #    f,
                #    g,
                #  -------------------------------------------
          E

      include_examples 'parse errors',
                       'with an array missing a comma between elements',
                       <<-PLIST,
 (
   a,
   b,
   (
     c
     d
   )
 )
                           PLIST
                       <<-E
[!] Array missing ',' in between objects
 #  -------------------------------------------
 #     (
 #       c
6>       d
         ^
 #     )
 #   )
 #  -------------------------------------------
                           E

      include_examples 'parse errors',
                       'with an unterminated dictionary',
                       <<-PLIST,
{
  a = e;
  b = j;
  d = (
    c
  );
                        PLIST
                       <<-E
[!] Unexpected end of string while parsing
 #  -------------------------------------------
 #      c
 #    );
7>\s\s
    ^
 #  -------------------------------------------
                        E

      include_examples 'parse errors',
                       'with an unterminated dictionary pair',
                       <<-PLIST,
{
  a = e;
  b = j;
  d = (
    c
  )
                         PLIST
                       <<-E
[!] Dictionary missing ';' after key-value pair for "d", found ""
 #  -------------------------------------------
 #      c
 #    )
7>\s\s
    ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'with a dictionary without an `=`',
                       '{a}',
                       <<-E
[!] Dictionary missing value for key "a", expected '=' and found "}"
 #  -------------------------------------------
1>  {a}
      ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'with a dictionary without a value',
                       '{ a = ; }',
                       <<-E
[!] Invalid character ";" in unquoted string
 #  -------------------------------------------
1>  { a = ; }
          ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'with an unterminated quoted string',
                       "{\na = 'bcd\n}",
                       <<-E
[!] Unterminated quoted string, expected ' but never found it
 #  -------------------------------------------
 #  {
2>  a = 'bcd
         ^
 #  }
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'with non-whitespace after the root object',
                       'abcd a',
                       <<-E
[!] Found additional characters after parsing the root plist object
 #  -------------------------------------------
1>  abcd a
         ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'when a data is unterminated',
                       '<1234',
                       <<-E
[!] Data missing closing '>'
 #  -------------------------------------------
1>  <1234
     ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'when the plist is empty',
                       '',
                       <<-E
[!] Unexpected end of string while parsing
 #  -------------------------------------------
1>\s\s
    ^
 #  -------------------------------------------
                         E

      include_examples 'parse errors',
                       'when the plist only contains whitespace',
                       "  \n\t\r\n\t \n ",
                       <<-E
[!] Unexpected end of string while parsing
 #  -------------------------------------------
 #\s\s
 #\s\s\t\s
5>\s\s\s
     ^
 #  -------------------------------------------
                         E
    end
  end
end
