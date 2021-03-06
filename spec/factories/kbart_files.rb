# frozen_string_literal: true

FactoryBot.define do
  factory :kbart_file do
    folder { "UMPEBC" }
    name { "UMPEBC_1970" }
    updated { "1970-01-01" }
    verified { false }
  end
end
