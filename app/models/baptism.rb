# frozen_string_literal: true

# Baptism model
class Baptism < ApplicationRecord
  belongs_to :parishioner, foreign_key: 'baptized_person', class_name: 'Baptism'
end
