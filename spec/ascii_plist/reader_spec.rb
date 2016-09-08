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
      before do
        @reader = Reader.new('{a = "a";"b" = b;"c" = "c";   d = d;}')
        @result = @reader.parse!
      end

      it 'should return a plist' do
        expect(@result).to be_a Plist
      end

      it 'should have a AsciiPlist::Dictionary as the root_object' do
        expect(@result.root_object).to be_a AsciiPlist::Dictionary
      end

      it 'should have four keys' do
        expect(@result.root_object.value.keys.count).to eql 4
      end
    end
  end
end
