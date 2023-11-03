# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/parishioners', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :baptisms
  fixtures :household
  fixtures :marriages

  before(:each) do
    @file = fixture_file_upload('profile-pic.jpeg', 'image/jpeg')
    @file2 = fixture_file_upload('profile-pic2.jpeg', 'image/jpeg')

    @file_wrong = fixture_file_upload('aaa.txt', 'text/plain')

    @example_test_parishioner = {
      first_name: '男人',
      last_name: '周',
      gender: '男',
      birth_at: Date.strptime('1990/01/01', '%Y/%m/%d'),
      postal_code: '433',
      address: '彰化縣田尾鄉福德巷359號',
      picture: @file,

      father: '',
      mother: '',
      father_id: nil,
      mother_id: nil,

      home_phone: '12512515',
      mobile_phone: '09123124512',
      nationality: '越南',
      profession: '醫生',
      company_name: '恐龍牙醫診所',

      move_in_date: Date.strptime('2013/01/01', '%Y/%m/%d'),
      original_parish: '',

      move_out_date: nil,
      move_out_reason: '',
      destination_parish: '',

      comment: '測試用範例教友'
    }

    @parishioner = Parishioner.find_by_id(1)
    @parishioner.picture.attach(@file)
  end

  path '/api/parishioners' do
    get('list parishioners') do
      tags 'Parishioner'
      security [Bearer: {}]

      description = 'Search from the following fields: home_number gender name home_phone mobile_phone.'

      parameter name: :any_field, in: :query, description:, schema: {
        type: :string
      }

      parameter name: :name, in: :query, description: 'Search from the combine of first_name and last_name', schema: {
        type: :string
      }

      parameter name: :is_archive, in: :query, description: 'Search in archive if the value is "true"', schema: {
        type: :string
      }

      request_body_example value: {
        any_field: '趙爸爸'
      }, name: 'query test parishioner', summary: 'Finding the specific parishioner'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:name) {}
        let(:is_archive) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          data = JSON.parse(response.body)

          @parishioner_archive = Parishioner.where('move_out_date is not null')

          expect(data.any? { |hash| hash['id'] == @parishioner_archive[0].id }).to be false
        end
      end

      response(200, 'Search in archive') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:name) {}
        let(:is_archive) { 'true' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          data = JSON.parse(response.body)

          @parishioner_archive = Parishioner.where('move_out_date is not null')

          expect(data.any? { |hash| hash['id'] == @parishioner_archive[0].id }).to be true
        end
      end

      response(200, 'Query search any_field') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { '%E8%B6%99%E7%88%B8%E7%88%B8' }
        let(:name) {}
        let(:is_archive) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @parishioner2 = Parishioner.find_by_id(5)

          # ApplicationRecord to hash
          parishioner_hash = @parishioner.as_json
          parishioner2_hash = @parishioner2.as_json

          # Delete unused fields
          parishioner_hash.except!(*%w[
                                     created_at updated_at
                                   ])
          parishioner2_hash.except!(*%w[
                                      created_at updated_at
                                    ])

          parishioner_hash['baptism'] = @parishioner.baptism.as_json
          parishioner_hash['confirmation'] = @parishioner.confirmation.as_json
          parishioner_hash['eucharist'] = @parishioner.eucharist.as_json
          parishioner_hash['father_instance'] = @parishioner.father_instance.as_json
          parishioner_hash['mother_instance'] = @parishioner.mother_instance.as_json

          parishioner_hash['child_for_father'] = @parishioner.child_for_father.as_json
          parishioner_hash['child_for_mother'] = @parishioner.child_for_mother.as_json

          parishioner_hash['wife'] = @parishioner.wife.as_json

          parishioner_hash['sibling'] = @parishioner.sibling.as_json
          parishioner_hash['children'] = @parishioner.children.as_json

          # expect(data[0]).to eq(parishioner_hash)
          parishioner2_hash['sibling'] = @parishioner2.sibling.as_json
          parishioner2_hash['children'] = @parishioner2.children.as_json

          expect(data[0]).to eq(parishioner2_hash)
        end
      end

      response(200, 'Query search name') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:name) { '%E7%88%B8%E7%88%B8' }
        let(:is_archive) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          data = data.map { |hash| hash['id'] }

          @parishioner2 = Parishioner.where('first_name LIKE ?', '爸爸').pluck('id')

          # ApplicationRecord to hash
          parishioner2_hash = @parishioner2.as_json

          expect(data).to eq(parishioner2_hash)
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:name) {}
        let(:is_archive) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    post('create parishioner') do
      tags 'Parishioner'
      security [Bearer: []]
      consumes 'multipart/form-data'
      # Name should be blank for the nesting problem
      parameter name: '', in: :formData, schema: {
        type: :object,
        properties: {
          first_name: { type: :string, example: '男人' },
          last_name: { type: :string, example: '周' },
          gender: { type: :string, example: '男' },
          birth_at: { type: :string, example: Date.strptime('1990/01/01', '%Y/%m/%d') },
          postal_code: { type: :string, example: '433' },
          address: { type: :string, example: '彰化縣田尾鄉福德巷359號' },
          picture: { type: :string, format: :binary },

          father: { type: :string },
          mother: { type: :string },
          father_id: { type: :integer },
          mother_id: { type: :integer },

          home_phone: { type: :string, example: '12512515' },
          mobile_phone: { type: :string, example: '09123124512' },
          nationality: { type: :string, example: '越南' },
          profession: { type: :string, example: '醫生' },
          company_name: { type: :string, example: '恐龍牙醫診所' },
          comment: { type: :string, example: '測試用範例教友' }
        },
        required: %w[first_name last_name gender birth_at]
      }

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:"") { @example_test_parishioner }

        run_test! do |response|
          data = JSON.parse(response.body)

          @example_test_parishioner.each_key do |key|
            next if key == :picture

            date_field = %i[birth_at move_in_date move_out_date]
            if date_field.include?(key)
              date_data = data[key.to_s]
              date_data = date_data.nil? ? nil : Date.strptime(data[key.to_s])

              expect(date_data).to eq(@example_test_parishioner[key])
            else
              expect(data[key.to_s]).to eq(@example_test_parishioner[key])
            end
          end
        end
      end

      response(201, 'Minimal data input') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:"") do
          {
            first_name: '名',
            last_name: '姓',

            birth_at: Date.strptime('1990/01/01', '%Y/%m/%d'),

            gender: '男',

            picture: ''
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
        end
      end

      response(403, 'Current user dose not have permission') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:"") {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Foreign key not found') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:"") do
          {
            first_name: '名',
            last_name: '姓',

            birth_at: Date.strptime('1990/01/01', '%Y/%m/%d'),

            gender: '男',

            picture: '',

            mother_id: 100
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          puts data

          expect(data['errors']).to eq(['教友資料中未能找到母親教友資料'])
        end
      end

      # Parishioner info incomplete test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:"") do
          {
            first_name: '', last_name: '', gender: '', birth_at: ''
          }
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Wrong picture extension') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:"") do
          temp = @example_test_parishioner

          temp['picture'] = @file_wrong

          temp
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data['errors']).to eq('圖片格式不屬於 ["image/jpeg", "image/png"]')
        end
      end
    end
  end

  path '/api/parishioners/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # input the unknown user name
      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 'unknown_id' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    patch('update parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]

      consumes 'multipart/form-data'
      # Name should be blank for the nesting problem
      parameter name: '', in: :formData, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          gender: { type: :string },
          birth_at: { type: :string },
          postal_code: { type: :string },
          address: { type: :string },
          picture: { type: :string, format: :binary },

          father: { type: :string },
          mother: { type: :string },
          father_id: { type: :integer },
          mother_id: { type: :integer },

          home_phone: { type: :string },
          mobile_phone: { type: :string },
          nationality: { type: :string },
          profession: { type: :string },
          company_name: { type: :string },
          comment: { type: :string }
        }
      }

      request_body_example value: {
        first_name: '偉人',
        last_name: '台灣'
      }, name: 'test name change', summary: 'Test parishioner update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { first_name: '偉人', last_name: '台灣', mother_id: 4, father_id: 5, picture: @file2 } }

        run_test! do
          parishioner = Parishioner.all[0]
          mother = Parishioner.find_by_id(4)
          father = Parishioner.find_by_id(5)

          expect(parishioner.full_name).to eq('台灣偉人')

          expect(parishioner.father_instance.id).to eq(father.id)
          expect(parishioner.father).to eq(father.full_name)

          expect(parishioner.mother_instance.id).to eq(mother.id)
          expect(parishioner.mother).to eq(mother.full_name)
        end
      end

      response(204, 'Delete association') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { father_id: '', mother_id: '' } }

        run_test! do
          parishioner = Parishioner.all[0]

          expect(parishioner.father_instance).to eq(nil)
        end
      end

      response(204, 'Blank picture value') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { picture: '' } }

        run_test! do
          # parishioner = Parishioner.all[0]
          # expect(parishioner.picture_url).to eq(nil)
        end
      end

      response(403, 'Current user have not permission') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { first_name: '台灣偉人' } }

        run_test!
      end

      response(422, 'Field is blank') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { first_name: '' } }

        run_test!
      end

      response(422, 'Father id not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { father_id: 100 } }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data['errors']).to eq('教友資料中未能找到父親教友資料')
        end
      end

      response(422, 'Home number not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { home_number: 100 } }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data['errors']).to eq('該家號不存在')
        end
      end
    end

    delete('delete parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]
      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }

        run_test!
      end

      # Current user have not permission
      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { Parishioner.all[0].id }

        run_test!
      end

      # The user does not exist
      response(404, 'User not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 'unknown_id' }

        run_test!
      end
    end
  end

  path '/api/parishioners/{_id}/picture' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('profile picture of parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]
      produces 'image/*'

      response(200, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @parishioner.id }

        run_test!
      end

      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[1].id }

        run_test!
      end
    end
  end

  path '/api/parishioners/{_id}/card' do
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('id card of parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]
      produces 'image/*'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @parishioner.id }

        run_test!
      end

      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 200 }

        run_test!
      end
    end
  end

  path '/api/parishioners/{_id}/card_back' do
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('id card back of parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]
      produces 'image/*'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @parishioner.id }

        run_test!
      end

      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 200 }

        run_test!
      end
    end
  end

  path '/api/parishioners/{_id}/certificate' do
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('certificate of parishioner') do
      tags 'Parishioner'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @parishioner.id }

        run_test!
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:_id) { 1 }

        run_test!
      end

      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 200 }

        run_test!
      end
    end
  end

  path '/api/id-cards' do
    post('id cards print of parishioners') do
      tags 'Parishioner'
      security [Bearer: {}]
      consumes 'application/json'

      parameter name: :ids, in: :body, schema: {
        type: :object
      }

      request_body_example value: {}, name: 'all print example', summary: 'print all parishioners'

      request_body_example value: {
        ids: [1, 2]
      }, name: 'ids example', summary: 'id cards of parishioners'

      response(200, 'empty id test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) {}

        run_test!
      end

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) do
          {
            ids: [1, 3]
          }
        end

        run_test!
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:ids) do
          {
            ids: [1, 3]
          }
        end

        run_test!
      end

      response(404, 'Baptize Not Found with empty result') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) do
          {
            ids: [555]
          }
        end

        run_test!
      end

      response(404, 'Baptize Not Found with multiple ids') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) do
          {
            ids: [1, 2, 4, 6_456_345]
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data['errors']).to eq('教友 ["錢女人", "孫媽媽"] 尚未登錄領洗資訊')
        end
      end
    end
  end
end
