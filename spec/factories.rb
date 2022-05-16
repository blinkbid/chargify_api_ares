# frozen_string_literal:true

FactoryBot.define do
  sequence :email do |n|
    "customer#{n}@example.com"
  end

  sequence :product_name do |n|
    "Product #{n}"
  end

  sequence :customer_id do |n|
    n
  end

  sequence :subscription_id do |n|
    n
  end

  sequence :product_id do |n|
    n
  end

  factory :customer, class: Chargify::Customer do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { FactoryBot.generate(:email) }
    organization { Faker::Company.name }
    created_at { 2.days.ago }
    updated_at { 1.hour.ago }
  end

  factory :product, class: Chargify::Product do
    name { FactoryBot.generate(:product_name) }
  end

  factory :product_family, class: Chargify::ProductFamily do
    name { Faker::Name.name }
    handle { 'mining' }
  end

  factory :subscription, class: Chargify::Subscription do
    balance_in_cents { 500 }
    current_period_ends_at { 3.days.from_now }
  end

  factory :subscription_with_extra_attrs, parent: :subscription do
    customer { build :customer }
    product { build :product }
    credit_card { 'CREDIT CARD' }
    bank_account { 'BANK ACCOUNT' }
    paypal_account { 'PAYPAL ACCOUNT' }
  end

  factory :component, class: Chargify::Component do
    name { Faker::Company.bs }
  end

  factory :quantity_based_component, class: Chargify::Component do
    name { Faker::Company.bs }
    unit_name { 'unit' }
    pricing_scheme { 'tiered' }
    component_type { 'quantity_based_component' }
  end

  factory :subscriptions_component, class: Chargify::Subscription::Component do
    name { Faker::Company.bs }
    unit_name { 'unit' }
    component_type { 'quantity_based_component' }
  end

  factory :coupon, class: Chargify::Coupon do
    name                   { '15% off' }
    code                   { '15OFF' }
    description            { '15% off for life' }
    percentage             { '14' }
    allow_negative_balance { false }
    recurring              { false }
    end_date               { 1.month.from_now }
  end
end
