# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :name
    t.decimal :money
  end
end
