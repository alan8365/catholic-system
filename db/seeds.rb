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

# Parishioner
first_parishioner = Parishioner.create({
                                         name: '許某某',
                                         gender: '男',
                                         birth_at: Date.strptime('1990/01/01', '%Y/%m/%d'),
                                         postal_code: '433',
                                         address: '台中市北區三民路某段某號',
                                         spouse: '王某某',
                                         father: '許某某',
                                         mother: '張某某',
                                         home_phone: '047221245',
                                         mobile_phone: '0987372612',
                                         nationality: '中華民國',
                                         profession: '資訊',
                                         company_name: '科技大學',

                                         sibling_number: 0,
                                         children_number: 0,

                                         move_in_date: Date.strptime('2013/01/01', '%Y/%m/%d'),
                                         original_parish: 'ＯＯ堂區',

                                         move_out_date: Date.strptime('2093/01/01', '%Y/%m/%d'),
                                         move_out_reason: '搬家',
                                         destination_parish: 'ＸＸ堂區',

                                         comment: '測試用教友一號'
                                       })

second_parishioner = Parishioner.create({
                                          name: '王某某',
                                          gender: '女',
                                          birth_at: Date.strptime('1990/02/02', '%Y/%m/%d'),
                                          postal_code: '433',
                                          address: '台中市北區三民路某段某號',
                                          spouse: '許某某',
                                          father: '王某某',
                                          mother: '陳某某',
                                          home_phone: '047221245',
                                          mobile_phone: '0987372612',
                                          nationality: '中華民國',
                                          profession: '資訊',
                                          company_name: '科技大學',

                                          sibling_number: 0,
                                          children_number: 0,

                                          move_in_date: Date.strptime('2013/01/01', '%Y/%m/%d'),
                                          original_parish: 'ＯＯ堂區',

                                          move_out_date: Date.strptime('2093/01/01', '%Y/%m/%d'),
                                          move_out_reason: '搬家',
                                          destination_parish: 'ＸＸ堂區',

                                          comment: '測試用教友二號'
                                        })

# Household

first_household = Household.create({
                                     home_number: 'CK123'
                                   })

# Parishioner association
first_parishioner.household = first_household
second_parishioner.household = first_household

first_parishioner.spouse_instance = second_parishioner
second_parishioner.spouse_instance = first_parishioner

first_parishioner.save
second_parishioner.save

# Household association
first_household.head_of_household = first_parishioner
first_household.save

# Baptism
Baptism.create({
                 baptized_at: Date.strptime('1980/10/29', '%Y/%m/%d'),
                 baptized_location: '彰化市聖十字架天主堂',
                 christian_name: '安東尼',

                 godfather: '張00',
                 presbyter: '黃世明神父',

                 parishioner_id: first_parishioner.id
               })

# Confirmation
Confirmation.create({
                      confirmed_at: Date.strptime('1980/10/29', '%Y/%m/%d'),
                      confirmed_location: '彰化市聖十字架天主堂',
                      christian_name: '安東尼',

                      godfather: '張00',
                      presbyter: '黃世明神父',

                      parishioner: first_parishioner
                    })
