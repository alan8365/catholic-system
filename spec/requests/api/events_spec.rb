# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/events', type: :request do
  fixtures :users, :event

  before(:each) do
    @example_test = {
      name: '五月花',

      start_at: Date.strptime('2023/5/2', '%Y/%m/%d'),

      comment: '測試用活動'
    }

    @event = Event.all[0]
  end

  path '/api/events' do
    get('list events') do
      tags 'Regular Donations'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        any_field: '聖誕'
      }, name: 'query test event', summary: 'Finding all test event'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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

      # any_field query
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { '%E8%81%96%E8%AA%95' }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          event_hash = @event.as_json
          event_hash.except!(*%w[
                               created_at updated_at
                             ])

          expect(data).to eq([event_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:date) {}

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

    post('create event') do
      tags 'Regular Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :event, in: :body, schema: {
        type: :object,
        required: %w[home_number]
      }

      request_body_example value: {
        name: '聖誕',
        start_at: Date.strptime('2023/12/25', '%Y/%m/%d'),

        comment: '測試用活動'
      }, name: 'test event', summary: 'Test event create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:event) { @example_test }

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
            if key == :start_at
              date_data = data[key.to_s]
              date_data = date_data.nil? ? nil : Date.strptime(data[key.to_s])

              expect(date_data).to eq(@example_test[key])
            else
              expect(data[key.to_s]).to eq(@example_test[key])
            end
          end
        end
      end

      # Current user dose not have permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:user) { @example_test }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Event already exist test
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:user) { { name: 'TT520' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Home number is blank
      response(422, 'Unprocessable Entity') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:user) {}

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

  path '/api/events/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show event') do
      tags 'Regular Donations'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @event.id }

        run_test! do |response|
          data = JSON.parse(response.body)

          event_hash = @event.as_json

          expect(data).to eq(event_hash)
        end
      end

      # input the unknown home number
      response(404, 'Not Found') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
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

    patch('update event') do
      tags 'Regular Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :event, in: :body, schema: {
        type: :object
      }

      request_body_example value: {
        home_number: 'TT521',
        head_of_event_id: 2
      }, name: 'test home number change', summary: 'Test event update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @event.id }
        let(:event) { { start_at: Date.strptime('2023/6/2', '%Y/%m/%d'), name: '六月花' } }

        run_test! do
          @event_updated = Event.find_by_id(@event.id)
          expect(@event_updated.name).to eq('六月花')
          expect(@event_updated.start_at).to eq(Date.strptime('2023/6/2', '%Y/%m/%d'))
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @event.id }
        let(:event) { {} }

        run_test!
      end
    end

    delete('delete event') do
      tags 'Regular Donations'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @event.id }

        run_test!
      end

      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @event.id }

        run_test!
      end
    end
  end
end
