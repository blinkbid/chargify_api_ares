require 'spec_helper'

describe Chargify::CustomerMetadata do

  describe '.inspect' do
    specify { expect(described_class.inspect).to eql("Chargify::CustomerMetadata(resource_id: integer, current_name: string, name: string, value: string)") }
  end

  describe "#inspect" do
    subject { described_class.new.inspect }
    it { should eql("#<Chargify::CustomerMetadata resource_id: nil, current_name: nil, name: nil, value: nil>") }
  end
end
