# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

User.create([
              { name: '管理員', username: 'admin', password: '!123abc', is_admin: true },
              { name: '普通使用者', username: 'basic', password: 'abc123!', is_modulator: true }
            ])

file = File.open Rails.root.join('asset', '教會資料.json'), 'r'
data = JSON.parse(file.read)
# Household init
household_data = data['household']

household_data.each do |h|
  household = Household.new({
                              home_number: h['home_number']
                            })

  unless household.save
    puts h['home_number']
    puts household.errors.full_messages
  end
end

# Parishioner
parishioner_data = data['parishioner']

parishioner_data.each do |p|
  parishioner = Parishioner.new(
    {
      id: p['id'],

      first_name: p['first_name'],
      last_name: p['last_name'],
      gender: p['gender'],
      birth_at: p['birth_at'],

      home_number: p['home_number'],

      postal_code: p['postal_code'],
      address: p['address'],
      father: p['father'],
      mother: p['mother'],

      home_phone: p['home_phone'],
      mobile_phone: p['mobile_phone'],

      nationality: p['nationality'],
      comment: p['comment']
    }
  )

  unless parishioner.save
    puts "par_id: #{p['id']}"
    puts parishioner.errors.full_messages
  end
end

parishioner_data.each_with_index do |p, _i|
  parishioner = Parishioner.find_by_id(p['id'])

  father = Parishioner.find_by_id(p['father_id'])
  mother = Parishioner.find_by_id(p['mother_id'])

  parishioner.father = father.full_name if father
  parishioner.mother = mother.full_name if mother

  parishioner.father_id = father.id if father
  parishioner.mother_id = mother.id if mother

  parishioner.save
end

# Head of household
household_data.each do |h|
  household = Household.find_by_home_number(h['home_number'])

  household.head_of_household = Parishioner.find_by_id(h['head_of_household_id'])
  household.save
end

# Archive unuse household
Household.all.each do |h|
  h.is_archive = true unless h.parishioners.any?
  h.save
end

special_household = Household.create({
                                       home_number: 'V',
                                       special: true,
                                       comment: '越南教友'
                                     })
guest_household = Household.create({
                                     home_number: 'G',
                                     guest: true,
                                     comment: '善心人士'
                                   })

# Baptism
baptism_data = data['baptism']

baptism_data.each do |b|
  baptism = Baptism.new(b)

  unless baptism.save
    puts "b_id: #{b['id']}, p_id: #{b['parishioner_id']}"
    puts baptism.errors.full_messages
  end
end

# Confirmation
confirmation_data = data['confirmation']

confirmation_data.each do |c|
  confirmation = Confirmation.new(c)

  unless confirmation.save
    puts "c_id: #{c['id']}, p_id: #{c['parishioner_id']}"
    puts confirmation.errors.full_messages
  end
end

# Marry
marry_data = data['marry']

marry_data.each do |m|
  marriage = Marriage.new(m)

  unless marriage.save
    puts "m_id: #{m['id']}, p_id: #{m['parishioner_id']}"
    puts marriage.errors.full_messages
  end
end

# Regular donation

# Regular donation random seeds
begin_date = Date.civil(2022, 1, 1)
end_date = Date.civil(2022, 12, -1)

date_range = begin_date..end_date
all_sunday = date_range.to_a.select { |k| k.wday.zero? }

all_household = Household.all

random_regular_donation = []
50.times do |_|
  home_number = all_household.sample.home_number

  donation_at = all_sunday.sample

  donation_amount = rand(1000..10_000)

  random_regular_donation << {
    home_number:,
    donation_at:,
    donation_amount:
  }
end

RegularDonation.create(random_regular_donation)

# Event
first_event = Event.create({
                             name: '聖誕',
                             start_at: Date.strptime('2023/12/25', '%Y/%m/%d')
                           })

second_event = Event.create({
                              name: '復活節',
                              start_at: Date.strptime('2023/04/09', '%Y/%m/%d')
                            })

third_event = Event.create({
                             name: '聖誕',
                             start_at: Date.strptime('2022/12/25', '%Y/%m/%d')
                           })

# Special donation
SpecialDonation.create([{
                         home_number: guest_household.home_number,
                         donation_at: Date.strptime('2023/12/24', '%Y/%m/%d'),
                         donation_amount: 15_000,

                         event: first_event
                       }])
50.times do |_i|
  home_number = all_household.sample.home_number

  date_range_array = (Date.civil(2022, 12, 1)..Date.civil(2022, 12, -1)).to_a
  donation_at = date_range_array.sample
  donation_amount = rand(1000..10_000)

  SpecialDonation.create({
                           home_number:,
                           donation_at:,
                           donation_amount:,

                           event: third_event
                         })
end
