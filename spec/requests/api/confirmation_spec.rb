require 'swagger_helper'

RSpec.describe 'api/confirmations', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :confirmation

  before(:each) do
    @example_test = {
      confirmed_at: '1981-11-11',
      confirmed_location: '彰化市聖十字架天主堂',
      christian_name: '聖施達',

      godmother: '許00',
      presbyter: '黃世明神父',

      parishioner_id: 1
    }
    @confirmation = Confirmation.all[0]
  end

  path '/api/confirmations' do
    get('list confirmations') do
      tags 'Confirmation'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '彰化'
      }, name: 'query test confirmation', summary: 'Finding the specific confirmation'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
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
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:any_field) { '%E5%BD%B0%E5%8C%96' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do
          data = JSON.parse(response.body)

          # ApplicationRecord to hash
          @confirmation_hash = @confirmation.as_json
          # Delete unused fields
          @confirmation_hash.except!(*%w[
                                       id
                                       created_at updated_at
                                       parishioner_id
                                     ])

          expect(data).to eq([@confirmation_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}

        run_test!
      end
    end

    post('create confirmation') do
      tags 'Confirmation'
      security [Bearer: {}]

      parameter name: :confirmation, in: :body, schema: {
        type: :object,
        required: %w[confirmed_at confirmed_location christian_name presbyter parishioner_id]
      }

      request_body_example value: {
        confirmed_at: '1981-11-11',
        confirmed_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godfather: '',
        godfather_id: nil,

        godmother: '許00',
        godmother_id: nil,

        presbyter: '黃世明神父',
        presbyter_id: nil,

        parishioner_id: 1
      }, name: 'test_confirmation', summary: 'Test confirmation create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:confirmation) { @example_test }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @example_test.each_key do |key|
            expect(data[key.to_s]).to eq(@example_test[key])
          end
        end
      end
    end
  end

  path '/api/confirmations/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show confirmation') do
      response(200, 'successful') do
        let(:_id) { '123' }

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

    patch('update confirmation') do
      response(200, 'successful') do
        let(:_id) { '123' }

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

    put('update confirmation') do
      response(200, 'successful') do
        let(:_id) { '123' }

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

    delete('delete confirmation') do
      response(200, 'successful') do
        let(:_id) { '123' }

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
end
