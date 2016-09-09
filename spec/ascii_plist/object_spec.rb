require 'spec_helper'

module AsciiPlist
  describe Object do
    describe 'in general' do
      before do
        @obj = Object.new('', nil)
      end

      it 'raises when calling the default write implementation' do
        expect { @obj.write(0, false) }.to raise_error(RuntimeError)
      end
    end

    describe '#write_annotation' do
      it 'outputs annotations as multiline' do
        object = Object.new('', 'this is a comment')
        expect(object.send(:write_annotation)).to be_eql ' /*this is a comment*/'
      end

      it 'returns an empty string if there is no annotation' do
        object = Object.new('', nil)
        expect(object.send(:write_annotation)).to be_eql ''
      end
    end
  end

  describe String do
    describe 'in general' do
      before do
        @obj = String.new('Value', 'A whimsical value')
      end

      it 'writes a non-pretty value without the comment' do
        output, indent = @obj.write(0, false)
        expect(output).to be_eql 'Value'
        expect(indent).to be_eql 0
      end

      it 'writes a pretty value with the comment' do
        output, indent = @obj.write(0, true)
        expect(output).to be_eql 'Value /*A whimsical value*/'
        expect(indent).to be_eql 0
      end
    end
  end

  describe QuotedString do
    describe 'in general' do
      before do
        @obj = QuotedString.new('Value', 'A whimsical value')
      end

      it 'writes a non-pretty value without the comment' do
        output, indent = @obj.write(0, false)
        expect(output).to be_eql '"Value"'
        expect(indent).to be_eql 0
      end

      it 'writes a pretty value with the comment' do
        output, indent = @obj.write(0, true)
        expect(output).to be_eql '"Value" /*A whimsical value*/'
        expect(indent).to be_eql 0
      end
    end
  end

  describe Array do
    describe 'in general' do
      before do
        value = [
          String.new('Values', 'Comment'),
          QuotedString.new('Can Be', 'Another Comment'),
          String.new('Mixed', nil),
          String.new('Types', nil)
        ]
        @obj = Array.new(value, 'A whimsical value')
      end

      it 'writes a non-pretty value without the comment' do
        output, indent = @obj.write(0, false)
        expect(output).to be_eql "(\n\tValues,\n\t\"Can Be\",\n\tMixed,\n\tTypes\n)"
        expect(indent).to be_eql 0
      end

      it 'writes a pretty value with the comment' do
        output, indent = @obj.write(0, true)
        expect(output).to be_eql "(\n\tValues /*Comment*/,\n\t\"Can Be\" /*Another Comment*/,\n\tMixed,\n\tTypes\n)"
        expect(indent).to be_eql 0
      end

      it 'writes an indented pretty value with the comment' do
        output, indent = @obj.write(2, true)
        expect(output).to eq "(\n\t\t\tValues /*Comment*/,\n\t\t\t\"Can Be\" /*Another Comment*/,\n\t\t\tMixed,\n\t\t\tTypes\n\t\t)"
        expect(indent).to eq 2
      end
    end
  end

  describe Dictionary do
    describe 'in general' do
      before do
        value = {
          String.new('ABCDEFFEDCBA', 'An Arbitrary Identifier') => Dictionary.new({}, 'Hmm')
        }
        @obj = Dictionary.new(value, 'A whimsical value')
      end

      it 'writes a non-pretty value without the comment' do
        output, indent = @obj.write(0, false)
        expect(output).to be_eql "{\n\tABCDEFFEDCBA = {\n\t};\n}"
        expect(indent).to be_eql 0
      end

      it 'writes a pretty value with the comment' do
        output, indent = @obj.write(0, true)
        expect(output).to be_eql "{\n\tABCDEFFEDCBA /*An Arbitrary Identifier*/ = {\n\t};\n}"
        expect(indent).to be_eql 0
      end
    end
  end
end
