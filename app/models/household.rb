# frozen_string_literal: true

class Household < ApplicationRecord
  validates :home_number, presence: true, uniqueness: true

  # Home number association
  has_many :parishioners, lambda {
                            where('move_out_date is null')
                          }, class_name: 'Parishioner', foreign_key: 'home_number', dependent: :nullify
  # condition: 'move_out_date is null'

  # Head of household association
  belongs_to :head_of_household, class_name: 'Parishioner', foreign_key: 'head_of_household', optional: true
end
