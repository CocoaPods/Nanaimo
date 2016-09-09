require 'spec_helper'

module AsciiPlist
  describe StringHelper do
    describe '#regular_whitespace?' do
      it 'returns true for pure whitespace characters' do
        input = ' '
        expect(StringHelper.regular_whitespace?(input)).to be_truthy
      end

      xit 'returns true for unicode seperators' do
      end

      it 'returns false for non-whitespace characters' do
        input = 'a'
        expect(StringHelper.regular_whitespace?(input)).to be_falsy
      end
    end

    describe '#special_whitespace?' do
      it 'returns true for special whitespace characters' do
        input = "\t"
        expect(StringHelper.special_whitespace?(input)).to be_truthy

        input = "\r"
        expect(StringHelper.special_whitespace?(input)).to be_truthy
      end

      it 'returns false for non-whitespace characters' do
        input = 'a'
        expect(StringHelper.regular_whitespace?(input)).to be_falsy
      end
    end

    describe '#whitespace?' do
      it 'returns true for special and plain whitespace characters' do
        tests = ["\t", "\r"]
        tests.each do |input|
          expect(StringHelper.whitespace?(input)).to be_truthy
        end
      end

      it 'returns false for non-whitespace characters' do
        tests = ['a', 'b', '-', '=', '0']
        tests.each do |input|
          expect(StringHelper.whitespace?(input)).to be_falsy
        end
      end
    end

    describe '#end_of_line?' do
      it 'returns true for a newline' do
        expect(StringHelper.end_of_line?("\n")).to be_truthy
      end

      it 'returns true for a carriage return' do
        expect(StringHelper.end_of_line?("\r")).to be_truthy
      end

      it 'returns false for non-newline characters' do
        expect(StringHelper.end_of_line?('A')).to be_falsy
      end
    end
  end
end
