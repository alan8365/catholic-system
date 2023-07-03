# frozen_string_literal: true
class CreateConfirmations < ActiveRecord::Migration[7.0]
  def change
    create_table :confirmations do |t|
      t.date 'confirmed_at', comment: 'The date the parishioner was confirmed'
      t.string 'confirmed_location', comment: 'The location where the parishioner was confirmed'

      t.string 'godfather', comment: "The name of the parishioner's godfather"
      t.string 'godmother', comment: "The name of the parishioner's godmother"
      t.string 'presbyter', comment: 'The name of the presbyter who confirmed the parishioner'

      t.integer 'godfather_id', comment: "The parishioner's godfather's id"
      t.integer 'godmother_id', comment: "The parishioner's godmother's id"
      t.integer 'presbyter_id', comment: "The parishioner's presbyter's id"

      t.integer 'parishioner_id', comment: "The parishioner's id"

      t.string 'comment'

      t.timestamps
    end

    add_foreign_key :confirmations, :parishioners, column: 'parishioner_id', on_update: :cascade, on_delete: :cascade

    add_foreign_key :confirmations, :parishioners, column: 'godfather_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :confirmations, :parishioners, column: 'godmother_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :confirmations, :parishioners, column: 'presbyter_id', on_delete: :nullify, on_update: :cascade
  end
end
