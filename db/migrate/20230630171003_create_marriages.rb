# frozen_string_literal: true

class CreateMarriages < ActiveRecord::Migration[7.0]
  def change
    create_table :marriages do |t|
      t.date 'marriage_at'
      t.string 'marriage_location'

      t.string 'groom'
      t.string 'bride'

      t.integer 'groom_id', comment: "The groom's id"
      t.integer 'bride_id', comment: "The bride's id"

      t.string 'groom_birth_at'
      t.string 'groom_father'
      t.string 'groom_mother'

      t.string 'bride_birth_at'
      t.string 'bride_father'
      t.string 'bride_mother'

      t.string 'presbyter'
      t.integer 'presbyter_id', comment: "The presbyter's id"

      t.string 'witness1'
      t.string 'witness2'

      t.string 'comment'

      t.timestamps
    end

    add_foreign_key :marriages, :parishioners, column: 'groom_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :marriages, :parishioners, column: 'bride_id', on_delete: :nullify, on_update: :cascade
    add_foreign_key :marriages, :parishioners, column: 'presbyter_id', on_delete: :nullify, on_update: :cascade
  end
end
