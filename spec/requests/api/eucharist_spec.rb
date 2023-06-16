require 'swagger_helper'

RSpec.describe 'api/eucharists', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :eucharist

  before(:each) do
    @example_test = {
      eucharist_at: '1981-11-11',
      eucharist_location: '彰化市聖十字架天主堂',
      christian_name: '聖施達',

      godmother: '許00',
      presbyter: '黃世明神父',

      parishioner_id: 2
    }
    @eucharist = Eucharist.all[0]
  end

  path '/api/eucharists' do
    get('list eucharists') do
      tags 'Eucharist'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '彰化'
      }, name: 'query test eucharist', summary: 'Finding the specific eucharist'

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
          @eucharist_hash = @eucharist.as_json

          # Delete unused fields
          @eucharist_hash.except!(*%w[
                                       id
                                       created_at updated_at
                                     ])

          expect(data).to eq([@eucharist_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}

        run_test!
      end
    end

    post('create eucharist') do
      tags 'Eucharist'
      security [Bearer: {}]

      consumes 'application/json'
      parameter name: :eucharist, in: :body, schema: {
        type: :object,
        required: %w[eucharist_at eucharist_location christian_name presbyter parishioner_id]
      }

      request_body_example value: {
        eucharist_at: '1981-11-11',
        eucharist_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godfather: '',
        godfather_id: nil,

        godmother: '許00',
        godmother_id: nil,

        presbyter: '黃世明神父',
        presbyter_id: nil,

        parishioner_id: 1
      }, name: 'test_eucharist', summary: 'Test eucharist create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:eucharist) { @example_test }

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

      # Current user dose not have permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:eucharist) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Eucharist info incomplete test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:eucharist) { {} }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Godparent xor test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        # let(:baptism) {  @example_test_baptism  }
        let(:baptism) do
          @example_test[:godfather] = 'ADD'

          @example_test
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

  path '/api/eucharists/{_parishioner_id}' do
    parameter name: '_parishioner_id', in: :path, type: :string, description: '_parishioner_id'

    get('show eucharist') do
      tags 'Eucharist'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { 'unknown_id' }

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

    patch('update eucharist') do
      tags 'Eucharist'
      security [Bearer: {}]

      consumes 'application/json'
      parameter name: :eucharist, in: :body, schema: {
        type: :object,
        required: %w[eucharist_at eucharist_location christian_name presbyter parishioner_id]
      }

      request_body_example value: {
        eucharist_at: '1981-11-11',
        eucharist_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godfather: '',
        godfather_id: nil,

        godmother: '許00',
        godmother_id: nil,

        presbyter: '黃世明神父',
        presbyter_id: nil,

        parishioner_id: 1
      }, name: 'test_eucharist', summary: 'Test eucharist update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }
        let(:eucharist) { { eucharist_location: '台中市聖十字架天主堂' } }

        run_test! do
          expect(Eucharist.all[0].eucharist_location).to eq('台中市聖十字架天主堂')
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }
        let(:eucharist) {}

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }
        let(:eucharist) { { eucharist_location: '' } }

        run_test!
      end
    end

    delete('delete eucharist') do
      tags 'Eucharist'
      security [Bearer: {}]

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }

        run_test!
      end

      # Current user dose not have permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_parishioner_id) { @eucharist.parishioner_id }

        run_test!
      end

      # The eucharist dose not exist
      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { 'unknown_id' }

        run_test!
      end
    end
  end
end
