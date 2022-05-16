require 'spec_helper'

describe Chargify::Subscription, :fake_resource do
  context 'strips nested association attributes before saving' do
    before do
      @subscription = build(:subscription_with_extra_attrs)
    end

    it 'strips customer' do
      expect(@subscription.attributes['customer']).to_not be_blank
      @subscription.save!
      expect(@subscription.attributes['customer']).to be_blank
    end

    it 'strips product' do
      expect(@subscription.attributes['product']).to_not be_blank
      @subscription.save!
      expect(@subscription.attributes['product']).to be_blank
    end

    it 'strips credit card' do
      expect(@subscription.attributes['credit_card']).to_not be_blank
      @subscription.save!
      expect(@subscription.attributes['credit_card']).to be_blank
    end

    it 'strips bank account' do
      expect(@subscription.attributes['bank_account']).to_not be_blank
      @subscription.save!
      expect(@subscription.attributes['bank_account']).to be_blank
    end

    it 'strips paypal account' do
      expect(@subscription.attributes['paypal_account']).to_not be_blank
      @subscription.save!
      expect(@subscription.attributes['paypal_account']).to be_blank
    end

    it "doesn't strip other attrs" do
      subscription = build(:subscription)

      expect { subscription.save! }.to_not change(subscription, :attributes)
    end
  end

  describe 'points to the correct payment profile' do
    before do
      @subscription = build(:subscription)
    end

    it 'does not have a payment profile' do
      expect(@subscription.payment_profile).to be_nil
    end

    it 'returns credit_card details' do
      @subscription.credit_card = 'CREDIT CARD'
      expect(@subscription.payment_profile).to eql 'CREDIT CARD'
    end

    it 'returns bank_account details' do
      @subscription.bank_account = 'BANK ACCOUNT'
      expect(@subscription.payment_profile).to eql 'BANK ACCOUNT'
    end

    it 'returns paypal_account details' do
      @subscription.paypal_account = 'PAYPAL ACCOUNT'
      expect(@subscription.payment_profile).to eql 'PAYPAL ACCOUNT'
    end
  end

  it 'creates a one-time charge' do
    id = generate(:subscription_id)
    subscription = build(:subscription, id:)
    allow(subscription).to receive(:persisted?).and_return(true)
    expected_response = { charge: { amount_in_cents: 1000, memo: 'one-time charge', success: true } }.to_xml
    FakeWeb.register_uri(:post, "#{test_domain}/subscriptions/#{id}/charges.xml", status: 201,
                                                                                  body: expected_response)

    response = subscription.charge(:amount => '10.00', 'memo' => 'one-time charge')

    expect(response.valid?).to be_truthy
    expect(response).to be_a(Chargify::Charge)
  end

  it 'finds by customer reference' do
    customer = build(:customer, reference: 'roger', id: 10)
    subscription = build(:subscription, id: 11, customer_id: customer.id, product: build(:product))

    expected_response = [subscription.attributes].to_xml(root: 'subscriptions')
    FakeWeb.register_uri(:get, "#{test_domain}/subscriptions.xml?customer_id=#{customer.id}", status: 200,
                                                                                              body: expected_response)
    allow(Chargify::Customer).to receive(:find_by_reference).with('roger').and_return(customer)
    expect(Chargify::Subscription.find_by_customer_reference('roger')).to eql(subscription)
  end

  it 'cancels the subscription' do
    @subscription = build(:subscription, id: 1)

    FakeWeb.register_uri(:get, "#{test_domain}/subscriptions/1.xml", body: @subscription.attributes.to_xml)

    expect { Chargify::Subscription.find(1) }.to_not raise_error
    @subscription.cancel
    expect { Chargify::Subscription.find(1) }.to raise_error
  end

  it 'migrates the subscription' do
    id = generate(:subscription_id)
    subscription = build(:subscription, id:)
    allow(subscription).to receive(:persisted?).and_return(true)
    expected_response = [subscription.attributes].to_xml(root: 'subscription')
    FakeWeb.register_uri(:post,
                         "#{test_domain}/subscriptions/#{id}/migrations.xml?migration%5Bproduct_handle%5D=upgraded-plan", status: 201, body: expected_response)

    response = subscription.migrate(product_handle: 'upgraded-plan')

    expect(response.valid?).to be_truthy
    expect(response.errors.any?).to be_falsey
    expect(response).to be_a(Chargify::Migration)
  end

  describe '#delayed_cancel' do
    context 'argument provided' do
      it 'schedules subscription cancellation' do
        subscription = build(:subscription, id: 1, cancel_at_end_of_period: false)

        subscription.delayed_cancel(true)
        expect(subscription.cancel_at_end_of_period).to eq(true)
      end

      it 'unschedules subscription cancellation' do
        subscription = build(:subscription, id: 1, cancel_at_end_of_period: true)

        subscription.delayed_cancel(false)
        expect(subscription.cancel_at_end_of_period).to eq(false)
      end
    end

    context 'no argument provided' do
      it 'schedules subscription cancellation' do
        subscription = build(:subscription, id: 1, cancel_at_end_of_period: false)

        subscription.delayed_cancel
        expect(subscription.cancel_at_end_of_period).to eq(true)
      end
    end
  end

  describe '#statements' do
    let(:subscription_id) { 1 }
    let(:statements) do
      [{ id: 1234 }, { id: 5678 }]
    end

    before do
      FakeWeb.register_uri(
        :get,
        "#{test_domain}/subscriptions/#{subscription_id}/statements.xml",
        status: 201,
        body: statements.to_xml
      )
    end

    it 'lists statements' do
      subscription = build(:subscription, id: subscription_id)
      expect(subscription.statements.first.id).to eq(1234)
      expect(subscription.statements.last.id).to eq(5678)
    end
  end

  describe '#statement' do
    let(:statement_id) { 1234 }
    let(:subscription_id) { 4242 }
    let(:statement) do
      { id: statement_id, subscription_id: }
    end

    before do
      FakeWeb.register_uri(
        :get,
        "#{test_domain}/statements/#{statement_id}.xml",
        status: 201,
        body: statement.to_xml
      )
    end

    it 'finds a statement' do
      subscription = build(:subscription, id: subscription_id)
      found = subscription.statement(statement_id)
      expect(found.id).to eql(statement_id)
      expect(found.subscription_id).to eql(subscription_id)
    end

    context 'when attempting to query a statement not under this subscription' do
      it 'raises an error' do
        subscription = build(:subscription, id: 9999)
        expect { subscription.statement(statement_id) }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end
  end

  describe '#invoices' do
    let(:subscription_id) { 1 }
    let(:invoices) do
      [{ id: 1234 }, { id: 5678 }]
    end

    before do
      # Note this uses the invoices endpoint, passing subscription id as a param
      FakeWeb.register_uri(
        :get,
        "#{test_domain}/invoices.xml?subscription_id=#{subscription_id}",
        status: 201,
        body: invoices.to_xml
      )
    end

    it 'lists invoices' do
      subscription = build(:subscription, id: subscription_id)
      expect(subscription.invoices.first.id).to eq(1234)
      expect(subscription.invoices.last.id).to eq(5678)
    end
  end

  describe '#invoice' do
    let(:invoice_id) { 1234 }
    let(:subscription_id) { 4242 }
    let(:invoice) do
      { id: invoice_id, subscription_id: }
    end

    before do
      FakeWeb.register_uri(
        :get,
        "#{test_domain}/invoices/#{invoice_id}.xml",
        status: 201,
        body: invoice.to_xml
      )
    end

    it 'finds an invoice' do
      subscription = build(:subscription, id: subscription_id)
      found = subscription.invoice(invoice_id)
      expect(found.id).to eql(invoice_id)
      expect(found.subscription_id).to eql(subscription_id)
    end

    context 'when attempting to query an invoice not under this subscription' do
      it 'raises an error' do
        subscription = build(:subscription, id: 9999)
        expect { subscription.invoice(invoice_id) }.to raise_error(ActiveResource::ResourceNotFound)
      end
    end
  end
end
