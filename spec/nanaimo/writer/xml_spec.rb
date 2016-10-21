require 'spec_helper'

module Nanaimo
  describe Writer::XMLWriter do
    let(:root_object) { nil }
    let(:plist) { Plist.new.tap { |p| p.root_object = root_object } }
    let(:pretty) { true }
    subject { Writer::XMLWriter.new(plist, pretty).write }
    let(:utf8) { Writer::UTF8 }

    def xml_plist(string)
      <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
#{string}
</plist>
      XML
    end

    describe 'writing normal ruby objects' do
      let(:root_object) { { 'key' => [{ 'a' => 'a', 'b' => %w(c d) }], 'quoted' => "foo\n\t\\bar" } }

      it 'writes the output' do
        expect(subject).to eq xml_plist("<dict>\n\t<key>key</key>\n\t<array>\n\t\t<dict>\n\t\t\t<key>a</key>\n\t\t\t<string>a</string>\n\t\t\t<key>b</key>\n\t\t\t<array>\n\t\t\t\t<string>c</string>\n\t\t\t\t<string>d</string>\n\t\t\t</array>\n\t\t</dict>\n\t</array>\n\t<key>quoted</key>\n\t<string>foo\n\t\\bar</string>\n</dict>")
      end
    end

    describe 'writing booleans' do
      let(:root_object) { [true, false] }

      it 'writes booleans' do
        expect(subject).to eq xml_plist("<array>\n\t<true/>\n\t<false/>\n</array>")
      end
    end

    describe 'writing numbers' do
      let(:root_object) { [1, 3.14] }

      it 'writes numbers as the proper types' do
        expect(subject).to eq xml_plist("<array>\n\t<integer>1</integer>\n\t<real>3.14</real>\n</array>")
      end
    end

    describe String do
      describe 'in general' do
        let(:root_object) { String.new('Value', 'A whimsical value') }

        it 'writes a pretty value' do
          expect(subject).to eq xml_plist('<string>Value</string>')
        end
      end

      describe 'escaping' do
        let(:root_object) { %(This\nis a \t string 'that ' "contains" wacky & <weird &> char><><&acters) }

        it 'writes a properly escaped value' do
          expect(subject).to eq xml_plist(<<-XML.strip)
<string>This
is a \t string 'that ' "contains" wacky &amp; &lt;weird &amp;&gt; char&gt;&lt;&gt;&lt;&amp;acters</string>
          XML
        end
      end
    end

    describe QuotedString do
      describe 'in general' do
        let(:root_object) { QuotedString.new('Value', 'A whimsical value') }

        it 'writes a pretty value' do
          expect(subject).to eq xml_plist('<string>Value</string>')
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

        it 'writes a pretty value' do
          expect(subject).to eq xml_plist("<array>\n\t<string>Values</string>\n\t<string>Can Be</string>\n\t<string>Mixed</string>\n\t<string>Types</string>\n</array>")
        end
      end
    end

    describe Dictionary do
      describe 'in general' do
        let(:root_object) do
          {
            'ABCDEFFEDCBA' => {}
          }
        end

        it 'writes a pretty value' do
          expect(subject).to eq xml_plist("<dict>\n\t<key>ABCDEFFEDCBA</key>\n\t<dict/>\n</dict>")
        end
      end
    end

    describe Data do
      describe 'in general' do
        let(:root_object) { Data.new('A'.upto('z').to_a.join, 'Data!') }

        it 'writes a pretty value' do
          serialized_data = "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpbXF1eX2BhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5\neg=="
          expect(subject).to eq xml_plist("<data>#{serialized_data}</data>")
        end
      end
    end
  end
end
