# frozen_string_literal: true

# User role added
class AddAccessControl < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :is_admin, :boolean, default: false
    add_column :users, :is_modulator, :boolean, default: false
  end
end
