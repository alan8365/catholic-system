# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/parishioners', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :household

  before(:each) do
    @file = fixture_file_upload('profile-pic.jpeg', 'image/jpeg')
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
      comment: '測試用範例教友'
    }
    @parishioner_properties = {
      name: { type: :string },
      gender: { type: :string },
      birth_at: { type: :string },
      postal_code: { type: :string },
      address: { type: :string },
      photo_url: { type: :string },
      picture: { type: :string, format: :binary },

      father: { type: :string },
      mother: { type: :string },
      spouse: { type: :string },
      father_id: { type: :integer },
      mother_id: { type: :integer },
      spouse_id: { type: :integer },

      home_phone: { type: :string },
      mobile_phone: { type: :string },
      nationality: { type: :string },
      profession: { type: :string },
      company_name: { type: :string },
      comment: { type: :string }
    }

    @parishioner = Parishioner.all[0]
    @parishioner.picture.attach(@file)
  end

  path '/api/parishioners' do
    get('list parishioners') do
      tags 'Parishioner'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '趙爸爸'
      }, name: 'query test parishioner', summary: 'Finding the specific parishioner'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Query search any_field
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { '%E8%B6%99%E7%88%B8%E7%88%B8' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq([{
                                'name' => '趙男人',
                                'gender' => '男',
                                'birth_at' => '1990-01-01',
                                'postal_code' => '433',
                                'address' => '台中市北區三民路某段某號',
                                'photo_url' => 'https://pp.qianp.com/zidian/kai/37/8d99.png',

                                'father' => '趙爸爸',
                                'mother' => '孫媽媽',
                                'spouse' => '錢女人',
                                'spouse_id' => nil,
                                'father_id' => nil,
                                'mother_id' => nil,

                                'home_phone' => '047221245',
                                'mobile_phone' => '0987372612',
                                'nationality' => '中華民國',

                                'profession' => '資訊',
                                'company_name' => '科技大學',
                                'comment' => '測試用男性教友一號'
                              }])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}

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
      # consumes 'application/json'
      # parameter name: :parishioner, in: :body, schema: {
      #   type: :object,
      #   properties: @parishioner_properties,
      #   required: %w[name gender birth_at]
      # }
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
          # photo_url: { type: :string, example: },
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
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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
            if key == :birth_at
              expect(Date.strptime(data[key.to_s])).to eq(@example_test_parishioner[key])
            elsif key == :picture
              next
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
      consumes 'application/json'
      parameter name: :parishioner, in: :body, schema: {
        type: :object,
        properties: @parishioner_properties
      }

      request_body_example value: {
        name: '台灣偉人', photo_url: ''
      }, name: 'test name change', summary: 'Test parishioner update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:parishioner) { { name: '台灣偉人' } }

        run_test!
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:parishioner) { { name: '台灣偉人' } }

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { Parishioner.all[0].id }
        let(:parishioner) { { name: '' } }

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
