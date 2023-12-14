# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/households', type: :request do
  fixtures :users, :parishioners, :household

  before(:each) do
    @example_test_household = {
      home_number: 'TT123',
      head_of_household_id: Parishioner.all[0].id,
      special: false,
      comment: '測試用家號'
    }

    @household = Household.find_by_home_number('TT520')
  end

  path '/api/households' do
    get('list households') do
      tags 'Households'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        description: 'aaa',
        require: false
      }

      parameter name: :is_archive, in: :query, description: 'Search in archive if the value is "true"', schema: {
        type: :string
      }

      parameter name: :is_guest, in: :query, description: 'Search in guest if the value is "true"', schema: {
        type: :string
      }

      parameter name: :is_special, in: :query, description: 'Search in special if the value is "true"', schema: {
        type: :string
      }

      parameter name: :page, in: :query, schema: {
        type: :string,
        require: false
      }

      parameter name: :per_page, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: 'TT'
      }, name: 'query test household', summary: 'Finding all test household'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:is_archive) {}
        let(:is_guest) {}
        let(:is_special) {}
        let(:page) {}
        let(:per_page) {}

        run_test! do
          data = JSON.parse(response.body)['data']

          @household_archive = Household.where(is_archive: false)

          data_home_number = data.map { |hash| hash['home_number'] }
          except_home_number = @household_archive.map { |hash| hash['home_number'] }

          expect(data_home_number).to eq(except_home_number)
        end
      end

      response(200, 'List archive households') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:is_archive) { 'true' }
        let(:is_guest) {}
        let(:is_special) {}
        let(:page) {}
        let(:per_page) {}

        run_test! do
          data = JSON.parse(response.body)['data']

          @household_archive = Household.where(is_archive: true)

          data_home_number = data.map { |hash| hash['home_number'] }
          except_home_number = @household_archive.map { |hash| hash['home_number'] }

          expect(data_home_number).to eq(except_home_number)
        end
      end

      # query
      response(200, 'Find TT in text field') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { 'TT' }
        let(:is_archive) {}
        let(:is_guest) {}
        let(:is_special) {}
        let(:page) {}
        let(:per_page) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)['data']

          household_hash = @household.as_json
          household_hash['head_of_household'] = @household.head_of_household.as_json
          household_hash['parishioners'] = @household.parishioners.as_json

          household_hash.except!(*%w[
                                   created_at updated_at
                                 ])

          expect(data).to eq([household_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:is_archive) {}
        let(:is_guest) {}
        let(:is_special) {}
        let(:page) {}
        let(:per_page) {}

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

    post('create household') do
      tags 'Households'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :household, in: :body, schema: {
        type: :object,
        required: %w[home_number]
      }

      request_body_example value: {
        home_number: 'TT123',
        head_of_household_id: '55866',
        special: false,
        comment: '測試用家號'
      }, name: 'test_user', summary: 'Test user create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:household) { @example_test_household }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          @example_test_household.each_key do |key|
            if key == :head_of_household_id
              expect(data['head_of_household']['id']).to eq(@example_test_household[key])
            else
              expect(data[key.to_s]).to eq(@example_test_household[key])
            end
          end
        end
      end

      # Current user dose not have permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:user) { @example_test_household }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Household already exist test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { { name: 'TT520' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Home number is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:user) {}

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

  path '/api/households/{_home_number}' do
    # You'll want to customize the parameter types...
    parameter name: '_home_number', in: :path, type: :string, description: '_home_number'

    get('show household') do
      tags 'Households'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_home_number) { 'TT520' }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['home_number']).to eq('TT520')
        end
      end

      # input the unknown home number
      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_home_number) { 'unknown_home_number' }

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

    patch('update household') do
      tags 'Households'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :household, in: :body, schema: {
        type: :object
      }

      request_body_example value: {
        home_number: 'TT521',
        head_of_household_id: 2,
        special: false,
        guest: false,
        is_archive: false
      }, name: 'test home number change', summary: 'Test household update'

      response(204, 'Change home_number and head_of_household') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_home_number) { 'TT520' }
        let(:household) { { home_number: 'TT521', head_of_household_id: 2 } }

        run_test! do
          expect(Household.find_by_home_number('TT521').home_number).to eq('TT521')
          expect(Household.find_by_home_number('TT521').head_of_household.id).to eq(2)
        end
      end

      response(204, 'Archive household') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_home_number) { 'TT520' }
        let(:household) { { is_archive: true } }

        run_test! do
          expect(Household.find_by_home_number('TT520').is_archive).to eq(true)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_home_number) { 'TT520' }
        let(:household) { { home_number: 'TT521' } }

        run_test!
      end
    end

    delete('delete household') do
      tags 'Households'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_home_number) { 'TT520' }

        run_test!
      end

      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_home_number) { 'TT520' }

        run_test!
      end
    end
  end
end
