# frozen_string_literal: true

class Parishioner < ApplicationRecord
  # Home number association
  belongs_to :household, class_name: 'Household', foreign_key: 'home_number', optional: true

  # Head of household association
  has_one :head_home_number, class_name: 'Household', foreign_key: 'head_of_household'

  # Self join association
  belongs_to :mother_instance, class_name: 'Parishioner', foreign_key: 'mother_id', optional: true
  belongs_to :father_instance, class_name: 'Parishioner', foreign_key: 'father_id', optional: true

  has_many :child_for_father, class_name: 'Parishioner', foreign_key: 'father_id'
  has_many :child_for_mother, class_name: 'Parishioner', foreign_key: 'mother_id'
  # Sacrament association
  has_one :baptism, class_name: 'Baptism', foreign_key: 'parishioner_id'
  has_one :confirmation, class_name: 'Confirmation', foreign_key: 'parishioner_id'
  has_one :eucharist, class_name: 'Eucharist', foreign_key: 'parishioner_id'

  has_one :wife, class_name: 'Marriage', foreign_key: 'groom_id'
  has_one :husband, class_name: 'Marriage', foreign_key: 'bride_id'

  # Image
  has_one_attached :picture

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :gender, presence: true
  validates :birth_at, presence: true

  before_validation :check_foreign_key_existence

  def picture_url
    if picture.key.nil?
      ''
    else
      ActiveStorage::Blob.service.path_for(picture.key)
    end
  end

  def full_name
    "#{last_name}#{first_name}"
  end

  def full_name_masked
    return full_name if /[a-zA-Z]+/.match?(first_name)

    first_name_masked = "Ｏ#{first_name[1..]}"
    "#{last_name}#{first_name_masked}"
  end

  def father_name
    if father_instance.nil?
      father
    else
      father_instance.full_name
    end
  end

  def mother_name
    if mother_instance.nil?
      mother
    else
      mother_instance.full_name
    end
  end

  def children
    data = Parishioner
           .where(father_id: id)
           .or(Parishioner.where(mother_id: id))

    { count: data.size, data: }
  end

  def sibling
    same_father = Parishioner
                  .where.not(father_id: nil)
                  .where.not(id:)
                  .where(father_id:)

    same_mother = Parishioner
                  .where.not(mother_id: nil)
                  .where.not(id:)
                  .where(mother_id:)

    data = same_father.or(same_mother)

    { count: data.size, data: }
  end

  def married?
    wife.nil? ^ husband.nil?
  end

  def address_divided
    pattern = /.{2}[市縣]/
    address_valid = address&.match(pattern)

    puts address

    if address_valid
      divide_address(address)
    else
      ['', '']
    end
  end

  private

  def check_foreign_key_existence
    if home_number.present? && !Household.exists?(home_number)
      errors.add(:base, I18n.t('activerecord.errors.models.parishioners.attributes.home_number.not_found'))
    end

    if father_id.present? && !Parishioner.exists?(father_id)
      errors.add(:base, I18n.t('activerecord.errors.models.parishioners.attributes.father_id.not_found'))
    end

    if mother_id.present? && !Parishioner.exists?(mother_id)
      errors.add(:base, I18n.t('activerecord.errors.models.parishioners.attributes.mother_id.not_found'))
    end

    true
  end

  def divide_address(address)
    require 'json'
    address = normalize_address(address)

    pattern = /(?<name>.{2}[市縣])/
    m = address.match(pattern)

    return ['', ''] if m.nil?

    name = m[:name]
    prefix = name

    file = File.open Rails.root.join('asset', 'taiwan_districts.json'), 'r'
    data = JSON.parse(file.read)

    data.each do |item|
      next unless item['name'] == name

      district = item['districts']
      district = district.map { |e| e['name'] }

      district_pattern = "(?<district>#{district.join('|')})"
      m = address.match(district_pattern)
      break if m.nil?

      district = m[:district]

      prefix += district
      break
    end
    postfix = address[prefix.length..]

    [prefix, postfix]
  end

  def normalize_address(address)
    address.gsub(/台(?<uni>[北中南東])/, '臺\k<uni>')
  end
end
