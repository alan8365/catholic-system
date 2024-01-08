class ChangeSpeDonationIndex < ActiveRecord::Migration[7.0]
  def up
    remove_index :special_donations, %i[event_id home_number]
  end

  def down
    add_index :special_donations, %i[event_id home_number], unique: true
  end
end
