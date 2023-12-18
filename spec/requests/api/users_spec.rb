# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/users', type: :request do
  fixtures :users
  before(:each) do
    @example_test_user = {
      name: '測試二號', username: 'test2', password: 'test123', comment: '測試用使用者', is_admin: false, is_modulator: true
    }
    @user_properties = {
      name: { type: :string },
      username: { type: :string },
      password: { type: :string },
      comment: { type: :string },
      is_admin: { type: :string },
      is_modulator: { type: :string }
    }
  end

  path '/api/users' do
    get('list users') do
      tags 'User'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        description: 'aaa',
        require: false
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
        any_field: 'test'
      }, name: 'query test user', summary: 'Finding all test user'

      parameter name: :non_page, in: :query, schema: {
        type: :string,
        require: false
      }

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:page) {}
        let(:per_page) {}
        let(:non_page) {}

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
        let(:any_field) { 'test' }
        let(:page) {}
        let(:per_page) {}
        let(:non_page) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)['data']
          expect(data).to eq([{
                               'comment' => 'The CRUD test user', 'is_admin' => false, 'is_modulator' => false, 'name' => '測試', 'username' => 'test1'
                             }])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:page) {}
        let(:per_page) {}
        let(:non_page) {}

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
      tags 'User'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        required: %w[name username password]
      }

      request_body_example value: {
        name: '測試二號', username: 'test2', password: 'test123', comment: '測試用使用者', is_admin: false, is_modulator: true
      }, name: 'test_user', summary: 'Test user create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { @example_test_user }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @example_test_user.each_key do |key|
            next if key == :password

            expect(data[key.to_s]).to eq(@example_test_user[key])
          end
        end
      end

      # Current user dose not have permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
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
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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
      tags 'User'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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

      # input the unknown user name
      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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

    patch('update user') do
      tags 'User'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: @user_properties
      }

      request_body_example value: {
        name: 'new1', is_admin: true, is_modulator: false
      }, name: 'test name change', summary: 'Test user update'

      response(204, 'Change name') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new1' } }

        run_test! do |_response|
          user = User.find_by_username('test1')

          expect(user.name).to eq('new1')
        end
      end

      response(204, 'Change password') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { password: 'password' } }

        run_test! do |_response|
          user = User.find_by_username('test1')

          expect(user.authenticate('password').id).to eq(user.id)
        end
      end

      response(204, 'Change to admin') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { is_admin: true, is_modulator: false } }

        run_test! do
          user = User.find_by_username('test1')

          expect(user.is_admin).to eq(true)
        end
      end

      response(204, 'Change password') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { password: 'test456' } }

        run_test! do
          user = User.find_by_username('test1')

          expect(user.authenticate('test456')).to_not eq(false)
        end
      end

      response(403, 'Current user have not permission') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new1' } }

        run_test!
      end

      # Can't change the username
      # response(400, 'Bad request') do
      #   let(:"authorization") { "Bearer #{authenticated_header 'admin'}" }
      #   let(:_username) { 'test1' }
      #   let(:user) { { username: 'test2' } }
      #
      #   run_test!
      # end

      # Field is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: '' } }

        run_test!
      end
    end

    put('update user') do
      tags 'User'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          password: { type: :string },
          comment: { type: :string },
          is_admin: { type: :string, format: 'binary' },
          is_modulator: { type: :string, format: 'binary' }
        },
        required: %w[name password]
      }

      request_body_example value: {
        name: '測試二號', username: 'test2', password: 'test123', comment: '測試用使用者', is_admin: false, is_modulator: true
      }, name: 'test put change', summary: 'Test user update in put method'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new2', password: 'abc123' } }

        run_test!
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_username) { 'test1' }
        let(:user) { { name: 'new2', password: 'abc123' } }

        run_test!
      end
    end

    delete('delete user') do
      tags 'User'
      security [Bearer: {}]
      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'test1' }

        run_test!
      end

      # Admin user can't be delete
      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'admin' }

        run_test!
      end

      # Current user have not permission
      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'basic'}" }
        let(:_username) { 'test1' }

        run_test!
      end

      # The user does not exist
      response(404, 'User not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_username) { 'unknown_user' }

        run_test!
      end
    end
  end
end
