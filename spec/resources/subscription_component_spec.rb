require 'spec_helper'

describe Chargify::Subscription::Component, :fake_resource do
  before(:each) do
    @subscription = Chargify::Subscription.new(:id => 1)
    @sc1 = Chargify::Subscription::Component.new(
      :subscription_id => @subscription.id,
      :component_id => 1,
      :allocated_quantity => 0,
      :name => "Paying Customers",
      :unit_name => "customers",
      :component_type => "quantity_based_component",
      :pricing_scheme => "stairstep"
    )
    @sc2 = Chargify::Subscription::Component.new(
      :subscription_id => @subscription.id,
      :component_id => 2,
      :unit_balance => 0,
      :name => "Text Messages",
      :unit_name => "text message",
      :component_type => "metered_component"
    )
    @subscriptions_components = [@sc1, @sc2]
  end

  describe "listing subscription components" do
    before(:each) do
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}.xml", :body => @subscription.to_xml)
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}/components.xml", :body => @subscriptions_components.to_xml(:root => 'components'))
    end

    it "returns an array of components from Chargify::Subscription::Component.find(:all, :params => {:subscription_id => @subscription.id})" do
      expected = @subscriptions_components
      actual   = Chargify::Subscription::Component.find(:all, :params => {:subscription_id => @subscription.id})
      actual   = actual.elements if actual.respond_to?(:elements)
      expect(actual).to eql(expected)
    end

    it "returns an array of components from Chargify::Subscription.find(2).components" do
      subscription = Chargify::Subscription.find(@subscription.id)
      expected     = @subscriptions_components
      actual       = subscription.components
      actual       = actual.elements if actual.respond_to?(:elements)
      expect(actual).to eql(expected)
    end
  end

  describe "reading a subscription component" do
    before(:each) do
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}.xml", :body => @subscription.to_xml)
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}/components/#{@sc1.component_id}.xml", :body => @sc1.to_xml)
    end

    it "returns the subscription's component resource from Chargify::Subscription::Component.find(1, :params => {:subscription_id => 1})" do
      expect(Chargify::Subscription::Component.find(@sc1.component_id, :params => {:subscription_id => @subscription.id})).to eql @sc1
    end

    it "returns the subscription's component resource from Chargify::Subscription.find(1).component(1)" do
      subscription = Chargify::Subscription.find(@subscription.id)
      expect(subscription.component(@sc1.component_id)).to eql @sc1
    end
  end

  describe "updating a subscription component" do
    before(:each) do
      @new_allocated_quantity = @sc1.allocated_quantity + 5

      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}.xml", :body => @subscription.to_xml)
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}/components/#{@sc1.component_id}.xml", :body => @sc1.to_xml)

      @sc1_prime = @sc1
      @sc1_prime.allocated_quantity = @new_allocated_quantity

      FakeWeb.register_uri(:put, "#{test_domain}/subscriptions/#{@subscription.id}/components/#{@sc1.component_id}.xml", :body => @sc1_prime.to_xml)
      FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/#{@subscription.id}/components/#{@sc1.component_id}.xml", :body => @sc1_prime.to_xml)
    end

    it "updates the subscription's component allocated quantity" do
      component = Chargify::Subscription::Component.find(@sc1.component_id, :params => {:subscription_id => @subscription.id})
      component.allocated_quantity = @new_allocated_quantity

      result = component.save
      expect(result).to be_truthy

      expect(Chargify::Subscription::Component.find(@sc1.component_id, :params => {:subscription_id => @subscription.id})).to eql @sc1_prime
    end
  end
end
