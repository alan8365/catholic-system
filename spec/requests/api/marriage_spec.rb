require 'swagger_helper'

RSpec.describe 'api/baptisms', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :baptisms

  before(:each) do
    @example_test = {
      baptized_at: '1981-11-11',
      baptized_location: '彰化市聖十字架天主堂',
      christian_name: '聖施達',

      godmother: '許00',
      presbyter: '黃世明神父',

      parishioner_id: 2
    }
    @baptism = Baptism.all[0]
  end

  path '/api/baptisms' do
    get('list baptisms') do
      tags 'Baptism'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '彰化'
      }, name: 'query test parishioner', summary: 'Finding the specific parishioner'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:any_field) {}

        after do |example|
          content = example.metadata[:response][:content] || {}
          example_spec = {
            'application/json' => {
              examples: {
                test_example: {
                  value: JSON.parse(response.body, symbolize_names: true)
                }
              }
            }
          }
          example.metadata[:response][:content] = content.deep_merge(example_spec)
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

        run_test! do |response|
          data = JSON.parse(response.body)

          # ApplicationRecord to hash
          baptism_hash = @baptism.as_json

          # Delete unused fields
          baptism_hash.except!(*%w[
                                 created_at updated_at
                               ])
          baptism_hash['parishioner'] = @baptism.parishioner.as_json

          expect(data).to eq([baptism_hash])
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

    post('create baptism') do
      tags 'Baptism'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :baptism, in: :body, schema: {
        type: :object,
        required: %w[baptized_at baptized_location christian_name presbyter parishioner_id]
      }

      request_body_example value: {
        baptized_at: '1981-11-11',
        baptized_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godfather: '',
        godfather_id: nil,

        godmother: '許00',
        godmother_id: nil,

        presbyter: '黃世明神父',
        presbyter_id: nil,

        parishioner_id: 1
      }, name: 'test_baptism', summary: 'Test baptism create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:baptism) { @example_test }

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
        let(:baptism) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Baptism info incomplete test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:baptism) { {} }

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

  path '/api/baptisms/{_parishioner_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_parishioner_id', in: :path, type: :string, description: '_parishioner_id'

    get('show baptism') do
      tags 'Baptism'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }

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

    patch('update baptism') do
      tags 'Baptism'
      security [Bearer: {}]
      consumes 'application/json'

      parameter name: :baptism, in: :body, schema: {
        type: :object,
      }

      request_body_example value: {
        baptized_at: '1981-11-11',
        baptized_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godmother: '許00',
        presbyter: '黃世明神父'
      }, name: 'test_baptism', summary: 'Test baptism update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }
        let(:baptism) { { baptized_location: '台中市聖十字架天主堂', parishioner_id: 2 } }

        run_test! do
          expect(Baptism.find_by_id(@baptism.id).baptized_location).to eq('台中市聖十字架天主堂')
          expect(Baptism.find_by_id(@baptism.id).parishioner_id).to eq(2)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }
        let(:baptism) { { baptized_location: '台中市聖十字架天主堂' } }

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }
        let(:baptism) { { presbyter: '' } }

        run_test!
      end
    end

    delete('delete baptism') do
      tags 'Baptism'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }

        run_test! do
          @temp = Baptism.find_by_parishioner_id(@baptism.parishioner_id)
          expect(@temp).to eq(nil)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_parishioner_id) { @baptism.parishioner_id }

        run_test!
      end

      # The baptism does not exist
      response(404, 'Baptism not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_parishioner_id) { 'unknown_id' }

        run_test!
      end
    end
  end
end
