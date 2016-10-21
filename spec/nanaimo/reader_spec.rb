require 'spec_helper'

module Nanaimo
  describe Reader do
    describe 'Arrays' do
      describe 'that are emtpy' do
        before do
          @reader = Reader.new('()')
          @result = @reader.parse!
        end

        it 'should return a plist' do
          expect(@result).to be_a Plist
        end

        it 'should have a Nanaimo::Array as the root_object' do
          expect(@result.root_object).to be_a Nanaimo::Array
        end

        it 'should have no values' do
          expect(@result.root_object.value.count).to eql 0
        end
      end

      describe 'with values' do
        before do
          @reader = Reader.new("(\n\tIDENTIFIER,\nANOTHER_IDENTIFIER)")
          @result = @reader.parse!
        end

        it 'should return a plist' do
          expect(@result).to be_a Plist
        end

        it 'should have a Nanaimo::Array as the root_object' do
          expect(@result.root_object).to be_a Nanaimo::Array
        end

        it 'should have two values' do
          expect(@result.root_object.value.count).to eql 2
        end

        it 'should maintain ordering' do
          expect(@result.root_object.value.map(&:value)).to eql %w(IDENTIFIER ANOTHER_IDENTIFIER)
        end
      end
    end

    describe 'reading annotations' do
      let(:string) { '{a /*annotation*/ = ( b /*another annotation*/ )}' }
      let(:reader) { Reader.new(string) }
      subject { reader.parse!.root_object }

      it 'should read the annotations correctly' do
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

      before do
        @reader = Reader.new(string)
        @result = @reader.parse!
      end

      it 'should return a plist' do
        expect(@result).to be_a Plist
      end

      it 'should have a Nanaimo::Dictionary as the root_object' do
        expect(@result.root_object).to be_a Nanaimo::Dictionary
      end

      it 'should have four keys' do
        expect(@result.root_object.value.keys.count).to eq 4
      end

      context 'when the dictionary is empty' do
        let(:string) { '{}' }

        it 'parses correctly' do
          expect(@result).to eq Plist.new(Nanaimo::Dictionary.new({}, ''), :ascii)
        end

        context 'and there are newlines' do
          let(:string) { "\t\n\t{\n\t\n}" }

          it 'parses correctly' do
            expect(@result).to eq Plist.new(Nanaimo::Dictionary.new({}, ''), :ascii)
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
          expect { subject }.to raise_error(Reader::ParseError, 'Data has an uneven number of hex digits')
        end
      end
    end
  end
end
