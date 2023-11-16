# frozen_string_literal: true

class CreateEvent < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.string 'name'

      t.date 'start_at'

      t.string 'comment'

      t.timestamps
    end
  end
end
