class Household < ApplicationRecord
  validates :home_number, presence: true, uniqueness: true

  # Home number association
  has_many :parishioners, class_name: "Parishioner", foreign_key: "home_number", dependent: :nullify

  # Head of household association
  belongs_to :head_of_household, class_name: "Parishioner", foreign_key: "head_of_household", optional: true
end
