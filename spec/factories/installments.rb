FactoryBot.define do
  factory :installment do
    amount_due { rand(5000..100_000) }
    due_date { rand(5..20) }
    association :loan
  end
end
