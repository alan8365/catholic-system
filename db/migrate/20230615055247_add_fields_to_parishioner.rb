# frozen_string_literal: true

class AddFieldsToParishioner < ActiveRecord::Migration[7.0]
  def change
    # add_column :parishioners, :sibling_number, :integer, default: 0
    # add_column :parishioners, :children_number, :integer, default: 0

    add_column :parishioners, :move_in_date, :date, null: true
    add_column :parishioners, :original_parish, :string, null: true

    add_column :parishioners, :move_out_date, :date, null: true
    add_column :parishioners, :move_out_reason, :string, null: true
    add_column :parishioners, :destination_parish, :string, null: true
  end
end
