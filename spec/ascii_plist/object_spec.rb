require 'spec_helper'

module AsciiPlist
  describe Object do
    describe 'in general' do
      before do
        @obj = Object.new('', '', nil)
      end

      it 'raises when calling the default write implementation' do
        expect{ @obj.write(0, false) }.to raise_error
      end 
    end

    describe '#write_annotation' do
      it 'outputs annotations as multiline' do
        object = Object.new('', '', 'this is a comment')
        expect(object.send :write_annotation).to be_eql ' /*this is a comment*/'
      end

      it 'returns an empty string if there is no annotation' do
        object = Object.new('', '', nil)
        expect(object.send :write_annotation).to be_eql ''
      end
    end
  end
end
