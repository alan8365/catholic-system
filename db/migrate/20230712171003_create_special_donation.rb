# frozen_string_literal: true

class CreateSpecialDonation < ActiveRecord::Migration[7.0]
  def change
    create_table :special_donations do |t|
      t.integer 'event_id'

      t.string 'home_number'

      t.date 'donation_at'
      t.integer 'donation_amount'

      t.string 'comment'

      t.boolean 'receipt', default: false

      t.timestamps
    end

    add_foreign_key :special_donations, :households,
                    column: 'home_number', primary_key: 'home_number', on_delete: :nullify, on_update: :cascade

    add_foreign_key :special_donations, :events,
                    column: 'event_id', primary_key: 'id', on_delete: :nullify, on_update: :cascade

    add_index :special_donations, %i[event_id home_number], unique: true
  end
end
