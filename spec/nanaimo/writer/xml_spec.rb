# frozen_string_literal: true

require 'spec_helper'

module Nanaimo
  describe Writer::XMLWriter do
    let(:root_object) { nil }
    let(:plist) { Plist.new.tap { |p| p.root_object = root_object } }
    let(:pretty) { true }
    let(:strict) { true }
    subject { Writer::XMLWriter.new(plist, pretty: pretty, strict: strict).write }
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

      context 'when strict is false' do
        let(:strict) { false }
        context 'and unknown object types are in the plist' do
          let(:root_object) do
            path_like = Class.new do
              def to_s
                '/dev/null'
              end
            end
            {
              'path_like' => path_like.new,
              'regexp' => /how? about \n [this]*$/ox,
              :symbol => :symbol
            }
          end

          it 'serializes their string representation' do
            expect(subject).to eq xml_plist("<dict>\n\t<key>path_like</key>\n\t<string>/dev/null</string>\n\t<key>regexp</key>\n\t<string>(?x-mi:how? about \\n [this]*$)</string>\n\t<key>symbol</key>\n\t<string>symbol</string>\n</dict>")
          end
        end
      end
    end

    describe 'writing booleans' do
      let(:root_object) { [true, false] }

      it 'writes booleans' do
        expect(subject).to eq xml_plist("<array>\n\t<true/>\n\t<false/>\n</array>")
      end
    end

    describe 'writing times' do
      # Use a fresh process to ensure writing Time does not depend on another
      # caller loading optional standard libraries.
      it 'does not depend on the caller requiring time' do
        require 'open3'
        require 'rbconfig'
        script = 'print Nanaimo::Writer::XMLWriter.new(Nanaimo::Plist.new(Time.at(0).utc)).write'
        lib = File.expand_path('../../../lib', __dir__)
        output, error, status = Open3.capture3(RbConfig.ruby, '-I', lib, '-r', 'nanaimo', '-e', script)
        expect(error).to eq ''
        expect(status).to be_success
        expect(output).to eq xml_plist('<date>1970-01-01T00:00:00Z</date>')
      end
    end

    describe 'writing dates' do
      require 'date'
      let(:local_time) { Time.new(2000, 1, 2, 3, 4, Rational(5_987_654, 1_000_000), '+05:30') }
      let(:root_object) do
        [
          Time.utc(2000, 1, 2, 3, 4, 5),
          local_time,
          DateTime.new(2000, 1, 2, 3, 4, 5, '-07:00'),
          Date.new(2000, 1, 2)
        ]
      end

      # Plist dates are UTC with whole seconds and a Z suffix; a Date has no
      # time of day or zone, so it is written as midnight UTC on that date.
      it 'writes every date type as a UTC timestamp with whole seconds' do
        expect(subject).to eq xml_plist("<array>\n\t<date>2000-01-02T03:04:05Z</date>\n\t<date>2000-01-01T21:34:05Z</date>\n\t<date>2000-01-02T10:04:05Z</date>\n\t<date>2000-01-02T00:00:00Z</date>\n</array>")
        expect(local_time.utc_offset).to eq 19_800
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

      describe 'carriage returns' do
        let(:root_object) { { "k\r\ney" => "x\ry\r\nz" } }

        # XML parsers normalize raw CR and CRLF to LF, so CR must be a
        # character reference to survive in both values and keys.
        it 'writes carriage returns as character references' do
          expect(subject).to eq xml_plist("<dict>\n\t<key>k&#13;\ney</key>\n\t<string>x&#13;y&#13;\nz</string>\n</dict>")
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
