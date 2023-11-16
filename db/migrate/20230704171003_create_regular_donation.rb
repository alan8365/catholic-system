# frozen_string_literal: true

class CreateRegularDonation < ActiveRecord::Migration[7.0]
  def change
    create_table :regular_donations do |t|
      t.string 'home_number'

      t.date 'donation_at'

      t.integer 'donation_amount'

      t.string 'comment'

      t.boolean 'receipt', default: false

      t.timestamps
    end

    add_foreign_key :regular_donations, :households,
                    column: 'home_number', primary_key: 'home_number', on_delete: :nullify, on_update: :cascade
  end
end
