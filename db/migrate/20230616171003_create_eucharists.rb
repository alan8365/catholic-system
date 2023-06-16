# frozen_string_literal: true

class CreateEucharists < ActiveRecord::Migration[7.0]
  def change
    create_table :eucharists do |t|
      t.date 'eucharist_at'
      t.string 'eucharist_location'
      t.string 'christian_name', comment: "The parishioner's Christian name"

      t.string 'godfather', comment: "The name of the parishioner's godfather"
      t.string 'godmother', comment: "The name of the parishioner's godmother"
      t.string 'presbyter', comment: 'The name of the presbyter who confirmed the parishioner'

      t.integer 'godfather_id', comment: "The parishioner's godfather's id"
      t.integer 'godmother_id', comment: "The parishioner's godmother's id"
      t.integer 'presbyter_id', comment: "The parishioner's presbyter's id"

      t.integer 'parishioner_id', comment: "The parishioner's id"

      t.timestamps
    end

    add_foreign_key :eucharists, :parishioners, column: 'parishioner_id', on_update: :cascade, on_delete: :cascade

    add_foreign_key :eucharists, :parishioners, column: 'godfather_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :eucharists, :parishioners, column: 'godmother_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :eucharists, :parishioners, column: 'presbyter_id', on_delete: :nullify, on_update: :cascade
  end
end
