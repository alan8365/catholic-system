require 'swagger_helper'

RSpec.describe 'api/marriages', type: :request do
  fixtures :users
  fixtures :parishioners
  fixtures :marriages

  before(:each) do
    @example_test = {
      marriage_at: '1961-11-11',
      marriage_location: '彰化市聖十字架天主堂',

      groom: '趙爸爸',
      bride: '孫媽媽',

      groom_id: 5,
      bride_id: 4,

      presbyter: '黃世明神父',

      witness1: '千里眼',
      witness2: '順風耳',

      comment: '結婚測試'
    }
    @marriage = Marriage.all[0]
  end

  path '/api/marriages' do
    get('list marriages') do
      tags 'Marriage'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '某某'
      }, name: 'query test parishioner', summary: 'Finding the specific parishioner'

      response(200, 'Successful') do
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
      response(200, 'Successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:any_field) { '%E8%B6%99%E7%94%B7%E4%BA%BA' }

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
          marriage_hash = @marriage.as_json

          # Delete unused fields
          marriage_hash.except!(*%w[
                                  created_at updated_at
                                ])
          marriage_hash['groom_instance'] = @marriage.groom_instance.as_json
          marriage_hash['bride_instance'] = @marriage.bride_instance.as_json

          expect(data).to eq([marriage_hash])
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

    post('create marriage') do
      tags 'Marriage'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :marriage, in: :body, schema: {
        type: :object,
        required: %w[marriage_at marriage_location groom bride]
      }

      request_body_example value: {
        marriage_at: '1961-11-11',
        marriage_location: '彰化市聖十字架天主堂',

        groom: '趙爸爸',
        bride: '孫媽媽',

        groom_id: 5,
        bride_id: 4,

        presbyter: '黃世明神父',

        witness1: '千里眼',
        witness2: '順風耳',

        comment: '結婚測試'
      }, name: 'test_marriage', summary: 'Test marriage create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:marriage) { @example_test }

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
        let(:marriage) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Marriage info incomplete test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:marriage) { {} }

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

  path '/api/marriages/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show marriage') do
      tags 'Marriage'
      security [Bearer: {}]

      response(200, 'Successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @marriage.id }

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

    patch('update marriage') do
      tags 'Marriage'
      security [Bearer: {}]
      consumes 'application/json'

      parameter name: :marriage, in: :body, schema: {
        type: :object
      }

      request_body_example value: {
        marriage_at: '1961-11-11',
        marriage_location: '彰化市聖十字架天主堂',

        groom: '趙爸爸',
        bride: '孫媽媽',

        groom_id: 5,
        bride_id: 4,

        presbyter: '黃世明神父',

        witness1: '千里眼',
        witness2: '順風耳',

        comment: '結婚測試'
      }, name: 'test_marriage', summary: 'Test marriage update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @marriage.id }
        let(:marriage) { { marriage_location: '台中市聖十字架天主堂' } }

        run_test! do
          expect(Marriage.find_by_id(@marriage.id).marriage_location).to eq('台中市聖十字架天主堂')
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @marriage.id }
        let(:marriage) { { marriage_location: '台中市聖十字架天主堂' } }

        run_test!
      end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @marriage.id }
        let(:marriage) { { groom: '' } }

        run_test!
      end
    end

    delete('delete marriage') do
      tags 'Marriage'
      security [Bearer: {}]

      response(204, 'Successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_id) { @marriage.id }

        run_test! do
          @temp = Marriage.find_by_id(@marriage.id)
          expect(@temp).to eq(nil)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @marriage.id }

        run_test!
      end

      # The marriage does not exist
      response(404, 'Marriage not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { 'unknown_id' }

        run_test!
      end
    end
  end
end
