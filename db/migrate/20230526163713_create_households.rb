class CreateHouseholds < ActiveRecord::Migration[7.0]
  def change
    create_table :households, id: false do |t|
      t.string "home_number", primary_key: true
      t.integer "head_of_household"

      t.timestamps
    end

    add_foreign_key :households, :parishioners, column: "head_of_household"

    # Add home number in parishioners
    add_column :parishioners, "home_number", :string
    add_foreign_key :parishioners, :households, column: "home_number", primary_key: "home_number"
  end
end
