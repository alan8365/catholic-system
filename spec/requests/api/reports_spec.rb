require 'swagger_helper'

RSpec.describe 'api/reports', type: :request do
  fixtures :users, :parishioners, :household, :regular_donation, :event, :special_donation

  path '/api/report/all_donations/year' do
    get('all_donation_yearly_report report') do
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

        run_test! do |response|
          # data = JSON.parse(response.body)
        end
      end

      response(400, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end

      response(401, 'Unauthorized') do
        let(:authorization) { '' }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end
    end
  end

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

      response(401, 'unauthorized') do
        let(:authorization) { '' }
        let(:date) { '2023/07' }
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

      response(400, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end

      response(401, 'Unauthorized') do
        let(:authorization) { '' }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end
    end
  end

  path '/api/report/regular_donations/receipt' do
    get('regular_donation_yearly_receipt report') do
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

        run_test!
      end

      response(400, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end

      response(401, 'Unauthorized') do
        let(:authorization) { '' }
        let(:date) { '2023/07' }
        let(:test) { 'true' }

        run_test!
      end
    end
  end

  path '/api/report/special_donations/event' do
    get('regular_donation_yearly_report report') do
      tags 'Reports'
      security [Bearer: {}]

      parameter name: :event_id, in: :query, schema: {
        type: :string,
        require: true
      }

      parameter name: :test, in: :query, schema: {
        type: :string,
        require: false
      }

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:event_id) { 1 }
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

      response(404, 'Not found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:event_id) { 6 }
        let(:test) { 'true' }

        run_test!
      end

      response(401, 'Unauthorized') do
        let(:authorization) { '' }
        let(:event_id) { 1 }
        let(:test) { 'true' }

        run_test!
      end
    end
  end

  path '/api/report/parishioner' do
    post('parishioner report') do
      tags 'Reports'
      security [Bearer: {}]
      consumes 'application/json'

      parameter name: :ids, in: :body, schema: {
        type: :object
      }

      parameter name: :test, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        pid: [1, 2, 3]
      }, name: 'report test', summary: 'Get 3 parishioners report by id'

      response(200, 'empty id test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) {}
        let(:test) { 'true' }

        run_test! do
          data = JSON.parse(response.body)
          data = data.transpose[0]
          data.delete_at(0)

          all_id = Parishioner
                   .all
                   .select('id')
                   .as_json
          all_id = all_id.map { |e| e['id'] }

          expect(data).to eq(all_id)
        end
      end

      response(200, 'multi id test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:ids) do
          {
            pid: [1, 2, 3]
          }
        end
        let(:test) { 'true' }

        run_test! do
          data = JSON.parse(response.body)
          data = data.transpose[0]
          data.delete_at(0)

          all_id = Parishioner
                   .where(id: [1, 2, 3])
                   .select('id')
                   .as_json
          all_id = all_id.map { |e| e['id'] }

          expect(data).to eq(all_id)
        end
      end

      response(401, 'Unauthorized') do
        let(:authorization) { '' }
        let(:ids) {}
        let(:test) { 'true' }

        run_test!
      end
    end
  end
end
