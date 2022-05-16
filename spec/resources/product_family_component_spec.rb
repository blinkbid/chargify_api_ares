require 'spec_helper'

describe Chargify::ProductFamily::Component do
  context 'create' do
    let(:component) { Chargify::ProductFamily::Component }
    let(:connection) { double('connection').as_null_object }
    let(:response) { double('response').as_null_object }

    before :each do
      allow_any_instance_of(component).to receive(:connection).and_return(connection)
      allow(response).to receive(:tap)
    end

    it 'should post to the correct url' do
      expect(connection).to receive(:post) do |path, body, headers|
        expect(path).to eql '/product_families/123/quantity_based_components.xml'

        response
      end

      component.create(:product_family_id => 123, :kind => 'quantity_based_component', :name => 'Foo Component')
    end

    it 'should not include the kind attribute in the post' do
      expect(connection).to receive(:post) do |path, body, headers|
        expect(body).to_not match(/kind/)

        response
      end

      component.create(:product_family_id => 123, :kind => 'quantity_based_component', :name => 'Foo Component')
    end

    it 'should have the component kind as the root' do
      expect(connection).to receive(:post) do |path, body, headers|
        #The second line in the xml should be the root.  This saves us from using nokogiri for this one example.
        expect(body.split($/)[1]).to match(/quantity_based_component/)

        response
      end

      component.create(:product_family_id => 123, :kind => 'quantity_based_component', :name => 'Foo Component')
    end
  end
end
