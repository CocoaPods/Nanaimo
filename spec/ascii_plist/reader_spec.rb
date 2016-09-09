require 'spec_helper'

module AsciiPlist
  describe Reader do
    describe 'Arrays' do
      describe 'that are emtpy' do
        before do
          @reader = Reader.new("()")
          @result = @reader.parse!
        end

        it 'should return a plist' do
          expect(@result).to be_a Plist
        end

        it 'should have a AsciiPlist::Array as the root_object' do
          expect(@result.root_object).to be_a AsciiPlist::Array
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

        it 'should have a AsciiPlist::Array as the root_object' do
          expect(@result.root_object).to be_a AsciiPlist::Array
        end

        it 'should have two values' do
          expect(@result.root_object.value.count).to eql 2
        end

        it 'should maintain ordering' do
          expect(@result.root_object.value.map(&:value)).to eql %w(IDENTIFIER ANOTHER_IDENTIFIER)
        end
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

      it 'should have a AsciiPlist::Dictionary as the root_object' do
        expect(@result.root_object).to be_a AsciiPlist::Dictionary
      end

      it 'should have four keys' do
        expect(@result.root_object.value.keys.count).to eq 4
      end

      context "when the dictionary is empty" do
        let(:string) { '{}' }

        it 'parses correctly' do
          expect(@result).to eq Plist.new(AsciiPlist::Dictionary.new({}, ''), 'ascii')
        end
      end
    end

    describe 'quoted strings' do
      let(:quoted_string) { %("\\"${ABC}\\"") }
      let(:reader) { Reader.new("{key = #{quoted_string}}") }
      subject { reader.parse!.root_object }

      it "parses" do
        expect(subject).to eq AsciiPlist::Dictionary.new({ AsciiPlist::String.new('key', '') => AsciiPlist::QuotedString.new(%("${ABC}"), '') }, '')
      end
    end
  end
end
