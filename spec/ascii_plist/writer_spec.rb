require 'spec_helper'

module AsciiPlist
  describe Writer do
    let(:root_object) { nil }
    let(:plist) { Plist.new.tap {|p| p.root_object = root_object } }
    let(:pretty) { true }
    subject { Writer.new(plist).write(pretty) }

    describe '#write_annotation' do
      context 'when there are annotations' do
        let(:root_object) { String.new('', 'this is a comment') }
        it "outputs them as multiline" do
          expect(subject).to eq " /*this is a comment*/"
        end
      end

      context 'when there are no annotations' do
        let(:root_object) { String.new('', '') }
        it "does not write one" do
          expect(subject).to eq ""
        end
      end
    end

    describe String do
      describe 'in general' do
        let(:root_object) { String.new('Value', 'A whimsical value') }

        context "when not pretty" do
          let(:pretty) { false }
          it 'writes without the comment' do
            expect(subject).to eq('Value')
          end
        end

        it 'writes a pretty value with the comment' do
          expect(subject).to eq('Value /*A whimsical value*/')
        end
      end
    end

    describe QuotedString do
      describe 'in general' do
        let(:root_object) { QuotedString.new('Value', 'A whimsical value') }

        it 'writes a pretty value with the comment' do
          expect(subject).to eq('"Value" /*A whimsical value*/')
        end
      end
    end

    describe Array do
      describe 'in general' do
        let(:root_object) do
          value = [
            String.new('Values', 'Comment'),
            QuotedString.new('Can Be', 'Another Comment'),
            String.new('Mixed', nil),
            String.new('Types', nil)
          ]
          Array.new(value, 'A whimsical value')
        end

        it 'writes a pretty value with the comment' do
          expect(subject).to eq "(\n\tValues /*Comment*/,\n\t\"Can Be\" /*Another Comment*/,\n\tMixed,\n\tTypes\n) /*A whimsical value*/"
        end
      end
    end

    describe Dictionary do
      describe 'in general' do
        let(:root_object) do
          value = {
            String.new('ABCDEFFEDCBA', 'An Arbitrary Identifier') => Dictionary.new({}, 'Hmm')
          }
          Dictionary.new(value, 'A whimsical value')
        end

        it 'writes a pretty value with the comment' do
          expect(subject).to eq "{\n\tABCDEFFEDCBA /*An Arbitrary Identifier*/ = {\n\t} /*Hmm*/;\n} /*A whimsical value*/"
        end
      end
    end
  end
end
