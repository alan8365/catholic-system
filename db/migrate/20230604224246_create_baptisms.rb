# frozen_string_literal: true

# Create baptism table
class CreateBaptisms < ActiveRecord::Migration[7.0]
  # @return [Object]
  def change
    create_table :baptisms do |t|
      t.date 'baptized_at', comment: 'The date the parishioner was baptized'
      t.string 'baptized_location', comment: 'The location where the parishioner was baptized'
      t.string 'christian_name', comment: "The parishioner's Christian name"

      t.string 'godfather', comment: "The name of the parishioner's godfather"
      t.string 'godmother', comment: "The name of the parishioner's godmother"
      t.string 'baptist', comment: 'The name of the person who baptized the parishioner'

      t.integer 'godfather_id', comment: "The parishioner's godfather's id"
      t.integer 'godmother_id', comment: "The parishioner's godmother's id"
      t.integer 'baptist_id', comment: "The parishioner's baptist's id"

      t.integer 'baptized_person', comment: "The parishioner's id"

      t.timestamps
    end

    add_foreign_key :baptisms, :parishioners, column: 'baptized_person', on_update: :cascade, on_delete: :cascade

    add_foreign_key :baptisms, :parishioners, column: 'godfather_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :baptisms, :parishioners, column: 'godmother_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :baptisms, :parishioners, column: 'baptist_id', on_delete: :nullify, on_update: :cascade
  end
end
