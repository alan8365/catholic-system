# frozen_string_literal: true

# create parishioner table
class CreateParishioners < ActiveRecord::Migration[7.0]
  def change
    create_table :parishioners do |t|
      # Necessary fields
      t.string 'first_name'
      t.string 'last_name'
      t.string 'gender'
      t.date 'birth_at'

      # Postal related fields
      t.string 'postal_code'
      t.string 'address'

      # Household related fields
      t.string 'father'
      t.string 'mother'
      t.string 'home_phone'
      t.string 'mobile_phone'
      t.string 'nationality'
      t.string 'profession'
      t.string 'company_name'

      # Database related fields
      t.string 'comment'
      t.timestamps

      # Foreign key fields
      t.integer 'mother_id'
      t.integer 'father_id'
    end

    add_foreign_key :parishioners, :parishioners, column: 'mother_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :parishioners, :parishioners, column: 'father_id', on_delete: :nullify, on_update: :cascade
  end
end
