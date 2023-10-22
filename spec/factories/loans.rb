require 'ffaker'

FactoryBot.define do
  factory :loan do
    amount { rand(5000..100_000) }
    term { rand(5..20) }
    association :user
  end
end
