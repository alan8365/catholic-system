# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

admin_user = User.create([
                           { name: "管理員", username: "admin", password: "!123abc", is_admin: true },
                         ])
basic_user = User.create([
                           { name: "普通使用者", username: "basic", password: "abc123!", is_modulator: true },
                         ])

first_parishioner = Parishioner.create({
                                         name: '許某某',
                                         gender: '男',
                                         birth_at: Date.strptime("1990/01/01", "%Y/%m/%d"),
                                         postal_code: "433",
                                         address: "台中市北區三民路某段某號",
                                         photo_url: "https://www.moedict.tw/%E6%9F%90%E6%9F%90%E4%BA%BA.png?font=wt064",
                                         spouse: "王某某",
                                         father: "許某某",
                                         mother: "張某某",
                                         home_phone: "047221245",
                                         mobile_phone: "0987372612",
                                         nationality: "中華民國",
                                         profession: "資訊",
                                         company_name: "科技大學",
                                         comment: "測試用教友一號",
                                       })

first_household = Household.create({
                                     home_number: "CK123",
                                   })

first_parishioner.home_number = first_household.home_number
first_parishioner.save

first_household.head_of_household = first_parishioner.id
first_household.save