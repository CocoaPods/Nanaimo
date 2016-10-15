require 'spec_helper'

describe AsciiPlist::XcodeProjectWriter do
  context 'writing identical projects' do
    projects = Dir[File.expand_path('../../fixtures/**/*.pbxproj', __FILE__)]
    it('needs projects!') { raise 'no projects!' } if projects.empty?
    projects.each do |project|
      it "serializes #{project.split(File::SEPARATOR)[-2]} exactly as it was read" do
        parsed = AsciiPlist::Reader.from_file(project).parse!
        serialized = described_class.new(parsed).write
        expect(serialized).to eq(
          File.read(project)
        )
      end
    end
  end
end
