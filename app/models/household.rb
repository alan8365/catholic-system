class Household < ApplicationRecord
  has_many :parishioners, class_name: "Parishioner", foreign_key: "home_number"

  # belongs_to :head_of_household, class_name: "Parishioner", foreign_key: "head_of_household"
end
