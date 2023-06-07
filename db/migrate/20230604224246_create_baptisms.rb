# frozen_string_literal: true

# Create baptism table
class CreateBaptisms < ActiveRecord::Migration[7.0]
  # @return [Object]
  def change
    create_table :baptisms do |t|
      # Create a new column for the baptized_at date
      t.date 'baptized_at', comment: 'The date the parishioner was baptized'
      # Create a new column for the baptized_location string
      t.string 'baptized_location', comment: 'The location where the parishioner was baptized'
      # Create a new column for the christian_name string
      t.string 'christian_name', comment: "The parishioner's Christian name"

      # Create a new column for the godfather string
      t.string 'godfather', comment: "The name of the parishioner's godfather"
      # Create a new column for the godmother string
      t.string 'godmother', comment: "The name of the parishioner's godmother"
      # Create a new column for the baptist string
      t.string 'baptist', comment: 'The name of the person who baptized the parishioner'

      t.integer 'godfather_id'
      t.integer 'godmother_id'
      t.integer 'baptist_id'

      t.integer 'baptized_person'

      t.timestamps
    end

    add_foreign_key :baptisms, :parishioners, column: 'baptized_person', on_update: :cascade, on_delete: :cascade

    add_foreign_key :baptisms, :parishioners, column: 'godfather_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :baptisms, :parishioners, column: 'godmother_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :baptisms, :parishioners, column: 'baptist_id', on_delete: :nullify, on_update: :cascade
  end
end
