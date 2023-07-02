# frozen_string_literal: true

# Baptism model
class Marriage < ApplicationRecord
  belongs_to :groom_instance, class_name: 'Parishioner', foreign_key: 'groom_id', optional: true
  belongs_to :bride_instance, class_name: 'Parishioner', foreign_key: 'bride_id', optional: true

  belongs_to :presbyter_instance, class_name: 'Parishioner', foreign_key: 'presbyter_id', optional: true

  validates :groom, presence: true
  validates :bride, presence: true

  validates :marriage_at, presence: true
  validates :marriage_location, presence: true
end
