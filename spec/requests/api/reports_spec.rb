require 'swagger_helper'

RSpec.describe 'api/reports', type: :request do
  fixtures :users, :parishioners, :household, :regular_donation

  path '/api/report/regular_donations/month' do
    get('regular_donation_monthly_report report') do
      tags 'Reports'
      security [Bearer: {}]

      date_description = 'The date field accepts the yyyy/mm format string for donation searches.
For example, "2023/7" would generate report for donations made in July 2023.'
      parameter name: :date, in: :query, description: date_description, schema: {
        type: :string,
        require: true
      }

      parameter name: :test, in: :query, schema: {
        type: :string,
        require: false
      }

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test!
      end

      response(400, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023' }
        let(:test) { 'true' }

        run_test!
      end
    end
  end

  path '/api/report/regular_donations/year' do
    get('regular_donation_yearly_report report') do
      tags 'Reports'
      security [Bearer: {}]

      date_description = 'The date field accepts the yyyy format string for donation searches.
For example, "2023" would generate report for donations made in 2023.'
      parameter name: :date, in: :query, description: date_description, schema: {
        type: :string,
        require: true
      }

      parameter name: :test, in: :query, schema: {
        type: :string,
        require: false
      }

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023' }
        let(:test) { 'true' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(400, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end
    end
  end
end
