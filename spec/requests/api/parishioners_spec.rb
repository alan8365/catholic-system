# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/parishioners', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :household

  before(:each) do
    @file = fixture_file_upload('profile-pic.jpeg', 'image/jpeg')
    @file2 = fixture_file_upload('profile-pic2.jpeg', 'image/jpeg')
    @example_test_parishioner = {
      name: '周男人',
      gender: '男',
      birth_at: Date.strptime('1990/01/01', '%Y/%m/%d'),
      postal_code: '433',
      address: '彰化縣田尾鄉福德巷359號',
      picture: @file,

      father: '',
      mother: '',
      spouse: '',
      father_id: nil,
      mother_id: nil,
      spouse_id: nil,

      home_phone: '12512515',
      mobile_phone: '09123124512',
      nationality: '越南',
      profession: '醫生',
      company_name: '恐龍牙醫診所',

      sibling_number: 0,
      children_number: 0,

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

      description = 'Search from the following fields: name home_number gender address father mother spouse nationality
profession company_name home_phone mobile_phone original_parish destination_parish move_out_reason comment.'

      parameter name: :any_field, in: :query, description: description, schema: {
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

      # Search in archive
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
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

      # Query search any_field
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { '%E8%B6%99%E7%88%B8%E7%88%B8' }
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

          # ApplicationRecord to hash
          parishioner_hash = @parishioner.as_json
          parishioner2_hash = Parishioner.find_by_id(5).as_json

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

          expect(data).to eq([parishioner_hash, parishioner2_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
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
          name: { type: :string, example: '周男人' },
          gender: { type: :string, example: '男' },
          birth_at: { type: :string, example: Date.strptime('1990/01/01', '%Y/%m/%d') },
          postal_code: { type: :string, example: '433' },
          address: { type: :string, example: '彰化縣田尾鄉福德巷359號' },
          picture: { type: :string, format: :binary },

          father: { type: :string },
          mother: { type: :string },
          spouse: { type: :string },
          father_id: { type: :integer },
          mother_id: { type: :integer },
          spouse_id: { type: :integer },

          home_phone: { type: :string, example: '12512515' },
          mobile_phone: { type: :string, example: '09123124512' },
          nationality: { type: :string, example: '越南' },
          profession: { type: :string, example: '醫生' },
          company_name: { type: :string, example: '恐龍牙醫診所' },
          comment: { type: :string, example: '測試用範例教友' }
        },
        required: %w[name gender birth_at]
      }

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:"") { @example_test_parishioner }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

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

      # Current user dose not have permission
      response(403, 'Forbidden') do
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

      # Parishioner info incomplete test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:"") do
          {
            name: '', gender: '', birth_at: ''
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
          name: { type: :string, example: '周男人' },
          gender: { type: :string, example: '男' },
          birth_at: { type: :string, example: Date.strptime('1990/01/01', '%Y/%m/%d') },
          postal_code: { type: :string, example: '433' },
          address: { type: :string, example: '彰化縣田尾鄉福德巷359號' },
          picture: { type: :string, format: :binary },

          father: { type: :string },
          mother: { type: :string },
          spouse: { type: :string },
          father_id: { type: :integer },
          mother_id: { type: :integer },
          spouse_id: { type: :integer },

          home_phone: { type: :string, example: '12512515' },
          mobile_phone: { type: :string, example: '09123124512' },
          nationality: { type: :string, example: '越南' },
          profession: { type: :string, example: '醫生' },
          company_name: { type: :string, example: '恐龍牙醫診所' },
          comment: { type: :string, example: '測試用範例教友' }
        }
      }

      request_body_example value: {
        name: '台灣偉人'
      }, name: 'test name change', summary: 'Test parishioner update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { name: '台灣偉人', spouse_id: 3, mother_id: 4, father_id: 5, picture: @file2 } }

        run_test! do
          parishioner = Parishioner.all[0]
          spouse = Parishioner.find_by_id(3)
          mother = Parishioner.find_by_id(4)
          father = Parishioner.find_by_id(5)

          expect(parishioner.name).to eq('台灣偉人')

          expect(parishioner.spouse_instance.id).to eq(spouse.id)
          expect(parishioner.spouse).to eq(spouse.name)

          expect(parishioner.father_instance.id).to eq(father.id)
          expect(parishioner.father).to eq(father.name)

          expect(parishioner.mother_instance.id).to eq(mother.id)
          expect(parishioner.mother).to eq(mother.name)
        end
      end

      # Delete association
      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { spouse_id: '', father_id: '', mother_id: '' } }

        run_test! do
          parishioner = Parishioner.all[0]

          expect(parishioner.spouse_instance).to eq(nil)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { name: '台灣偉人' } }

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:"") { { name: '' } }

        run_test!
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
end
