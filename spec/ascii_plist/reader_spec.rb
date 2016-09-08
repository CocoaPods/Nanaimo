require 'spec_helper'

module AsciiPlist
  describe Reader do
    describe 'reading root level arrays' do
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

      xit 'should have two values' do
        expect(@result.root_object.value.count).to eql 2
      end

      xit 'should maintain ordering' do
        expect(@result.root_object.value[0].value).to eql 'IDENTIFIER'
      end
    end

    describe 'reading root level dictionaries' do
      before do
        @reader = Reader.new('{a = "a";"b" = b;"c" = "c";   d = d;}')
        @result = @reader.parse!
      end

      xit 'should return a plist' do
        expect(@result).to be_a Plist
      end

      xit 'should have a AsciiPlist::Dictionary as the root_object' do
        expect(@result.root_object).to be_a AsciiPlist::Dictionary
      end

      xit 'should have four keys' do
        expect(@result.root_object.value.keys.count).to eql 4
      end
    end
  end
end
