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
        tests = ["\t", "\r"]
        tests.each do |input|
          expect(StringHelper.is_whitespace?(input)).to be_truthy
        end
      end

      it 'returns false for non-whitespace characters' do
        tests = ['a', 'b', '-', '=', '0']
        tests.each do |input|
          expect(StringHelper.is_whitespace?(input)).to be_falsy
        end
      end
    end

    describe '#is_end_of_line?' do
      it 'returns true for a newline' do
        expect(StringHelper.is_end_of_line?("\n")).to be_truthy
      end

      it 'returns true for a carriage return' do
        expect(StringHelper.is_end_of_line?("\r")).to be_truthy
      end

      it 'returns false for non-newline characters' do
        expect(StringHelper.is_end_of_line?('A')).to be_falsy
      end
    end

    describe '#index_of_next_non_space' do
      it 'can return a single line comment annotation' do
        input = "//this is a comment.\n("
        index, comment = StringHelper.index_of_next_non_space(input, 0)
        expect(comment).to be_eql 'this is a comment.'
        expect(index).to be_eql 21 # (
      end

      it 'can return a sigle line multi line comment annotation' do
        input = '/*this is a comment.*/ ('
        index, comment = StringHelper.index_of_next_non_space(input, 0)
        expect(comment).to be_eql 'this is a comment.'
        expect(index).to be_eql 23 # (
        expect(input[index]).to be_eql '('
      end

      it 'can return a multi line comment annotation' do
        input = "/*this is a comment.\nthat spans across multiple lines.*/ ("
        index, comment = StringHelper.index_of_next_non_space(input, 0)
        expect(comment).to be_eql "this is a comment.\nthat spans across multiple lines."
        expect(index).to be_eql 57 # (
        expect(input[index]).to be_eql '('
      end
    end
  end
end
