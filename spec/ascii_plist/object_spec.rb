require 'spec_helper'

module AsciiPlist
  describe Object do
    describe 'in general' do
      before do
        @obj = Object.new('', '', nil)
      end

      it 'raises when calling the default write implementation' do
        expect { @obj.write(0, false) }.to raise_error(RuntimeError)
      end
    end

    describe '#write_annotation' do
      it 'outputs annotations as multiline' do
        object = Object.new('', '', 'this is a comment')
        expect(object.send(:write_annotation)).to be_eql ' /*this is a comment*/'
      end

      it 'returns an empty string if there is no annotation' do
        object = Object.new('', '', nil)
        expect(object.send(:write_annotation)).to be_eql ''
      end
    end
  end

  describe String do
    describe 'in general' do
      before do
        @obj = String.new('Value', 'String', 'A whimsical value')
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
        @obj = QuotedString.new('Value', 'QuotedString', 'A whimsical value')
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
          String.new('Values', 'String', 'Comment'),
          QuotedString.new('Can Be', 'String', 'Another Comment'),
          String.new('Mixed', 'String', nil),
          String.new('Types', 'String', nil)
        ]
        @obj = Array.new(value, 'Data', 'A whimsical value')
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
    end
  end

  describe Dictionary do
    describe 'in general' do
      before do
        value = {
          String.new('ABCDEFFEDCBA', 'String', 'An Arbitrary Identifier') => Dictionary.new({}, 'PBXNativeProject', 'Hmm')
        }
        @obj = Dictionary.new(value, 'Dictionary', 'A whimsical value')
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
