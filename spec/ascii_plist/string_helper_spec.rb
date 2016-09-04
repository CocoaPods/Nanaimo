require 'spec_helper'

module AsciiPlist
  describe StringHelper do
    describe '#is_regular_whitespace?' do
      it 'returns true for pure whitespace characters' do
        input = ' '  
        expect(StringHelper.is_regular_whitespace?(input)).to be_truthy
      end

      xit 'returns true for unicode seperators' do
      end

      it 'returns false for non-whitespace characters' do
        input = 'a'  
        expect(StringHelper.is_regular_whitespace?(input)).to be_falsy
      end
    end

    describe '#is_special_whitespace?' do
      it 'returns true for special whitespace characters' do
        input = "\t"  
        expect(StringHelper.is_special_whitespace?(input)).to be_truthy
        
        input = "\r"
        expect(StringHelper.is_special_whitespace?(input)).to be_truthy
      end

      it 'returns false for non-whitespace characters' do
        input = 'a'  
        expect(StringHelper.is_regular_whitespace?(input)).to be_falsy
      end
    end

    describe '#is_whitespace?' do
      it 'returns true for special and plain whitespace characters' do
        tests = [ "\t", "\r" ]
        tests.each do |input|
          expect(StringHelper.is_whitespace?(input)).to be_truthy
        end
      end

      it 'returns false for non-whitespace characters' do
        tests = [ 'a', 'b', '-', '=', '0' ]
        tests.each do |input|
          expect(StringHelper.is_whitespace?(input)).to be_falsy
        end
      end
    end

    describe '#is_end_of_line?' do
    end

    describe '#index_of_next_non_space' do
    end
  end
end

