require 'spec_helper'

module AsciiPlist
  describe Writer do
    let(:root_object) { nil }
    let(:plist) { Plist.new.tap {|p| p.root_object = root_object } }
    let(:pretty) { true }
    subject { Writer.new(plist, pretty).write }
    let(:utf8) { Writer::UTF8 }

    describe '#write_annotation' do
      context 'when there are annotations' do
        let(:root_object) { String.new('', 'this is a comment') }
        it "outputs them as multiline" do
          expect(subject).to eq "#{utf8} /*this is a comment*/\n"
        end
      end

      context 'when there are no annotations' do
        let(:root_object) { String.new('a', '') }
        it "does not write one" do
          expect(subject).to eq "#{utf8}a\n"
        end
      end
    end

    describe "writing normal ruby objects" do
      let(:root_object) { {"key" => [{"a" => "a", "b" => ["c", "d"]}], "quoted" => "foo\n\t\\bar"} }

      it "writes the output" do
        expect(subject).to eq("#{utf8}{\n\tkey = (\n\t\t{\n\t\t\ta = a;\n\t\t\tb = (\n\t\t\t\tc,\n\t\t\t\td,\n\t\t\t);\n\t\t},\n\t);\n\tquoted = \"foo\\n\\t\\bar\";\n}\n")
      end
    end

    describe String do
      describe 'in general' do
        let(:root_object) { String.new('Value', 'A whimsical value') }

        context "when not pretty" do
          let(:pretty) { false }
          it 'writes without the comment' do
            expect(subject).to eq("#{utf8}Value\n")
          end
        end

        it 'writes a pretty value with the comment' do
          expect(subject).to eq("#{utf8}Value /*A whimsical value*/\n")
        end
      end
    end

    describe QuotedString do
      describe 'in general' do
        let(:root_object) { QuotedString.new('Value', 'A whimsical value') }

        it 'writes a pretty value with the comment' do
          expect(subject).to eq(%(#{utf8}"Value" /*A whimsical value*/\n))
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
          expect(subject).to eq "#{utf8}(\n\tValues /*Comment*/,\n\t\"Can Be\" /*Another Comment*/,\n\tMixed,\n\tTypes,\n) /*A whimsical value*/\n"
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
          expect(subject).to eq "#{utf8}{\n\tABCDEFFEDCBA /*An Arbitrary Identifier*/ = {\n\t} /*Hmm*/;\n} /*A whimsical value*/\n"
        end
      end
    end

    describe Data do
      describe 'in general' do
        let(:root_object) { Data.new('A'.upto('z').to_a.join, 'Data!') }

        it 'writes a pretty value with the comment' do
          serialized_data = "<4142 4344 4546 4748\n 494a 4b4c 4d4e 4f50\n 5152 5354 5556 5758\n 595a 5b5c 5d5e 5f60\n 6162 6364 6566 6768\n 696a 6b6c 6d6e 6f70\n 7172 7374 7576 7778\n 797a>"
          expect(subject).to eq "#{utf8}#{serialized_data} /*Data!*/\n"
        end
      end
    end
  end
end
