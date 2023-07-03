# frozen_string_literal: true

# Create households table
class CreateHouseholds < ActiveRecord::Migration[7.0]
  def change
    create_table :households, id: false do |t|
      t.string 'home_number', primary_key: true
      t.integer 'head_of_household'

      t.boolean 'special', default: false

      t.string 'comment'

      t.timestamps
    end

    add_foreign_key :households, :parishioners, column: 'head_of_household', on_update: :cascade, on_delete: :nullify

    # Add home number in parishioners
    add_column :parishioners, 'home_number', :string
    add_foreign_key :parishioners, :households, column: 'home_number', primary_key: 'home_number', on_delete: :nullify,
                    on_update: :cascade
  end
end
