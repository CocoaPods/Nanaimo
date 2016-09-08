require 'spec_helper'

module AsciiPlist
  describe Reader do
    describe 'reading root level arrays' do
      before do
        @reader = Reader.new("(\n\tIDENTIFIER\n)")
        @result = @reader.parse!
      end

      it 'should return a plist' do
        expect(@result).to be_a Plist
      end

      it 'should have a AsciiPlist::Array as the root_object' do
        expect(@result.root_object).to be_a AsciiPlist::Array
      end
    end
  end
end
