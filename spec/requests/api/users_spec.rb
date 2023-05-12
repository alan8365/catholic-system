require 'swagger_helper'

RSpec.describe 'api/users', type: :request do
  fixtures :users

  path '/api/users' do
    get('list users') do
      security [Bearer: {}]

      response(200, 'successful') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        let(:"authorization") { "Bearer error token" }

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

    post('create user') do
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          username: { type: :string },
          password: { type: :string },
        },
        required: %w[name username password]
      }

      response(201, "Created") do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { { name: '測試二號', username: 'test2', password: 'test123' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(403, "Forbidden") do
        let(:"authorization") { "Bearer #{authenticated_header 'basic'}" }
        let(:user) { { name: '測試二號', username: 'test2', password: 'test123' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # User already exist test
      response(422, "Unprocessable Entity") do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { { name: '測試', username: 'test1', password: 'test123' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # User info incomplete test
      response(422, "Unprocessable Entity") do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { { name: '', username: '', password: '' } }

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

  path '/api/users/{_username}' do
    # You'll want to customize the parameter types...
    parameter name: '_username', in: :path, type: :string, description: '_username'

    get('show user') do
      security [Bearer: {}]
      response(200, 'successful') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'admin' }

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
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'unknown_user_name' }

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

    # TODO deny username change
    patch('update user') do
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          password: { type: :string },
        },
      }

      response(204, 'No Content') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new1' } }

        run_test!
      end

      response(422, 'No Content') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: '' } }

        run_test!
      end
    end

    put('update user') do
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          password: { type: :string },
        },
        required: %w[name password]
      }
      response(204, 'No Content') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new2', password: 'abc123' } }

        run_test!
      end
    end

    delete('delete user') do
      security [Bearer: {}]
      response(204, 'successful') do
        let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }

        run_test!
      end
    end
  end
end
