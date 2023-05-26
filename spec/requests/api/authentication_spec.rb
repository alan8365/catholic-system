require 'swagger_helper'

RSpec.describe 'api/authentication', type: :request do
  fixtures :users

  path '/api/auth/login' do
    post('login authentication') do
      tags 'Auth'
      consumes 'application/json'
      parameter name: :userInfo, in: :body, schema: {
        type: :object,
        properties: {
          username: { type: :string },
          password: { type: :string },
        },
        required: %w[username password]
      }
      request_body_example value: { username: 'admin', password: '!123abc' }, name: 'admin', summary: 'Admin login'
      request_body_example value: { username: 'basic', password: 'abc123!' }, name: 'basic', summary: 'Basic login'

      response(200, 'OK') do
        let(:userInfo) { { username: 'admin', password: '!123abc' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['username']).to eq('admin')
        end
      end
    end
  end
end
