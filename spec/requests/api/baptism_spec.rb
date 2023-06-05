require 'swagger_helper'

RSpec.describe 'api/baptism', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :baptism

  before(:each) do
    @example_test_baptism = {
      baptized_at: '1981-11-11',
      baptized_location: '彰化市聖十字架天主堂',
      christian_name: '聖施達',

      godmother: '許00',
      baptist: '黃世明神父',

      baptized_person: 1
    }
    @baptism = Baptism.all[0]
  end

  path '/api/baptism' do

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

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq([{ 'baptized_at' => '1980-10-29',
                                'baptized_location' => '彰化市聖十字架天主堂',
                                'christian_name' => '安東尼',

                                'godfather' => '張00',
                                'godmother' => nil,
                                'baptist' => '黃世明神父',

                                'baptized_person' => 0 }])
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
        required: %w[baptized_at baptized_location christian_name baptist baptized_person]
      }

      request_body_example value: {
        baptized_at: '1981-11-11',
        baptized_location: '彰化市聖十字架天主堂',
        christian_name: '聖施達',

        godfather: '',
        godfather_id: nil,

        godmother: '許00',
        godmother_id: nil,

        baptist: '黃世明神父',
        baptist_id: nil,

        baptized_person: 1
      }, name: 'test_baptism', summary: 'Test baptism create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:baptism) { @example_test_baptism }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @example_test_baptism.each_key do |key|
            expect(data[key.to_s]).to eq(@example_test_baptism[key])
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
          @example_test_baptism[:godfather] = 'ADD'

          @example_test_baptism
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

  path '/api/baptism/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show baptism') do
      tags 'Baptism'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @baptism.id }

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
        baptist: '黃世明神父'
      }, name: 'test_baptism', summary: 'Test baptism update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @baptism.id }
        let(:baptism) { { baptized_location: '台中市聖十字架天主堂' } }

        run_test! do
          expect(Baptism.all[0].baptized_location).to eq('台中市聖十字架天主堂')
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @baptism.id }
        let(:baptism) { { baptized_location: '台中市聖十字架天主堂' } }

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @baptism.id }
        let(:baptism) { { baptist: '' } }

        run_test!
      end
    end

    delete('delete baptism') do
      tags 'Baptism'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @baptism.id }

        run_test! do
          @temp = Baptism.find_by_id(@baptism.id)
          expect(@temp).to eq(nil)
        end
      end


      # Current user have not permission
      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @baptism.id }

        run_test!
      end

      # The baptism does not exist
      response(404, 'Baptism not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 'unknown_id' }

        run_test!
      end
    end
  end
end
