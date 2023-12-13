# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/regular_donations', type: :request do
  fixtures :users, :parishioners, :household, :regular_donation

  before(:each) do
    @example_test = {
      home_number: 'TT520',

      donation_at: Date.strptime('2023/7/2', '%Y/%m/%d'),
      donation_amount: 1000,

      receipt: true,

      comment: '測試用奉獻'
    }

    @regular_donation = RegularDonation.all[0]
  end

  path '/api/regular_donations' do
    get('list regular_donations') do
      tags 'Regular Donations'
      security [Bearer: {}]
      parameter name: :any_field, in: :query, schema: {
        type: :string,
        require: false
      }

      date_description = 'The date field accepts the yyyy/m format string for donation searches.
For example, "2023/7" would search for donations made in July 2023.'
      parameter name: :date, in: :query, description: date_description, schema: {
        type: :string,
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
        any_field: 'TT',
        date: '2023/6'
      }, name: 'query test regular_donation', summary: 'Finding all test regular_donation'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:date) {}
        let(:page) {}
        let(:per_page) {}

        run_test!
      end

      # any_field query
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { 'TT' }
        let(:date) {}
        let(:page) {}
        let(:per_page) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          regular_donation_hash = @regular_donation.as_json
          regular_donation_hash.except!(*%w[
                                          created_at updated_at
                                        ])
          regular_donation_hash['household'] = @regular_donation.household.as_json

          expect(data).to eq([regular_donation_hash])
        end
      end

      # date query
      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:date) { '2023/6' }
        let(:page) {}
        let(:per_page) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          regular_donation_hash = @regular_donation.as_json
          regular_donation_hash.except!(*%w[
                                          created_at updated_at
                                        ])

          regular_donation_hash['household'] = @regular_donation.household.as_json
          # regular_donation_hash['household']['head_of_household'] =
          #   @regular_donation.household.head_of_household.as_json

          expect(data).to eq([regular_donation_hash])
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:date) {}
        let(:page) {}
        let(:per_page) {}

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

    post('create regular_donation') do
      tags 'Regular Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :regular_donation, in: :body, schema: {
        type: :object,
        required: %w[home_number]
      }

      request_body_example value: {
        home_number: 'TT520',

        donation_at: Date.strptime('2023/7/2', '%Y/%m/%d'),
        donation_amount: 1000,

        receipt: true,

        comment: '測試用奉獻'
      }, name: 'test_donation', summary: 'Test donation create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:regular_donation) { @example_test }

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
            if key == :donation_at
              date_data = data[key.to_s]
              date_data = date_data.nil? ? nil : Date.strptime(data[key.to_s])

              expect(date_data).to eq(@example_test[key])
            else
              expect(data[key.to_s]).to eq(@example_test[key])
            end
          end
        end
      end

      response(403, 'Current user dose not have permission') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:regular_donation) { @example_test }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'RegularDonation already exist test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:regular_donation) do
          {
            name: 'TT520',
            donation_at: Date.strptime('2023/06/29', '%Y/%m/%d'),
            donation_amount: 200
          }
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

      response(422, 'Home number is blank') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:regular_donation) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Donation_at is not sunday') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:regular_donation) do
          {
            home_number: 'TT520',

            donation_at: Date.strptime('2023/7/3', '%Y/%m/%d'),
            donation_amount: 1000
          }
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

      response(422, 'Donation_at is not future') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:regular_donation) do
          {
            home_number: 'TT520',

            donation_at: Date.parse('Sunday') + 7,
            donation_amount: 1000
          }
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

  path '/api/regular_donations/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show regular_donation') do
      tags 'Regular Donations'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @regular_donation.id }

        run_test! do |response|
          data = JSON.parse(response.body)

          regular_donation_hash = @regular_donation.as_json
          regular_donation_hash['household'] = @regular_donation.household.as_json

          expect(data).to eq(regular_donation_hash)
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

    patch('update regular_donation') do
      tags 'Regular Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :regular_donation, in: :body, schema: {
        type: :object
      }

      request_body_example value: {
        home_number: 'TT521',
        head_of_regular_donation_id: 2
      }, name: 'test home number change', summary: 'Test regular_donation update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @regular_donation.id }
        let(:regular_donation) { { donation_at: Date.strptime('2023/7/9', '%Y/%m/%d'), donation_amount: 1000 } }

        run_test! do
          @regular_donation_updated = RegularDonation.find_by_id(@regular_donation.id)
          expect(@regular_donation_updated.donation_at).to eq(Date.strptime('2023/7/9', '%Y/%m/%d'))
          expect(@regular_donation_updated.donation_amount).to eq(1000)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @regular_donation.id }
        let(:regular_donation) { {} }

        run_test!
      end
    end

    delete('delete regular_donation') do
      tags 'Regular Donations'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @regular_donation.id }

        run_test!
      end

      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @regular_donation.id }

        run_test!
      end
    end
  end
end
