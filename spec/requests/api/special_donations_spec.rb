# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'api/special_donations', type: :request do
  fixtures :users, :parishioners, :household, :event, :special_donation

  before(:each) do
    @example_test = {
      event_id: 1,
      home_number: 'TT520',

      donation_at: Date.strptime('2023/7/2', '%Y/%m/%d'),
      donation_amount: 1000,

      receipt: true,

      comment: '測試用奉獻'
    }

    @special_home_number_hash = {
      event_id: 1,
      home_number: 'V',

      donation_at: Date.strptime('2023/7/2', '%Y/%m/%d'),
      donation_amount: 3000,

      receipt: false,

      comment: '測試用奉獻'
    }

    @special_donation = SpecialDonation.all[0]
  end

  path '/api/special_donations' do
    get('list special_donations') do
      tags 'Special Donations'
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

      parameter name: :event_id, in: :query, schema: {
        type: :string,
        require: false
      }

      request_body_example value: {
        date: '2023/6'
      }, name: 'query test special_donation', summary: 'Finding all test special_donation'

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:date) {}
        let(:event_id) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test! do
          data = JSON.parse(response.body)
          data = data.map { |e| e.slice('id') }

          all_id = SpecialDonation
                   .all
                   .select('id')
                   .as_json

          expect(data).to eq(all_id)
        end
      end

      response(200, 'any_field query test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { 'TT520' }
        let(:date) {}
        let(:event_id) {}

        run_test! do |response|
          data = JSON.parse(response.body)

          @special_donations = SpecialDonation.where(home_number: 'TT520')
          special_donation_hash = @special_donations.as_json

          special_donation_hash = special_donation_hash.map do |e|
            head_of_household = SpecialDonation.find_by_id(e['id']).household.head_of_household
            e['name'] = head_of_household.full_name
            e['first_name'] = head_of_household.first_name
            e['last_name'] = head_of_household.last_name

            e
          end

          # special_donation_hash.except!(*%w[
          #                                 created_at updated_at
          #                               ])
          # special_donation_hash['household'] = @special_donation.household.as_json

          expect(data).to eq(special_donation_hash)
        end
      end

      response(200, 'any_field name test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { '%E7%94%B7%E4%BA%BA' }
        let(:date) {}
        let(:event_id) {}

        run_test! do |response|
          data = JSON.parse(response.body)

          @special_donations = SpecialDonation.where(home_number: 'TT520')
          special_donation_hash = @special_donations.as_json

          special_donation_hash = special_donation_hash.map do |e|
            head_of_household = SpecialDonation.find_by_id(e['id']).household.head_of_household
            e['name'] = head_of_household.full_name
            e['first_name'] = head_of_household.first_name
            e['last_name'] = head_of_household.last_name

            e
          end

          # special_donation_hash.except!(*%w[
          #                                 created_at updated_at
          #                               ])
          # special_donation_hash['household'] = @special_donation.household.as_json

          expect(data).to eq(special_donation_hash)
        end
      end

      response(200, 'date query test') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:date) { '2023/6' }
        let(:event_id) {}

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          date_range = Date.civil(2023, 6, 1)..Date.civil(2023, 6, -1)
          @special_donations = SpecialDonation.where(donation_at: date_range)

          special_donation_hash = @special_donations.as_json

          special_donation_hash = special_donation_hash.map do |e|
            head_of_household = SpecialDonation.find_by_id(e['id']).household.head_of_household
            e['name'] = head_of_household&.full_name
            e['first_name'] = head_of_household&.first_name
            e['last_name'] = head_of_household&.last_name

            e
          end

          expect(data).to eq(special_donation_hash)
        end
      end

      response(200, 'event_id query') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) {}
        let(:date) {}
        let(:event_id) { 1 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @special_donations = Event.find_by_id(1).special_donations
          special_donation_hash = @special_donations.as_json

          special_donation_hash = special_donation_hash.map do |e|
            head_of_household = SpecialDonation.find_by_id(e['id']).household.head_of_household
            e['name'] = head_of_household&.full_name
            e['first_name'] = head_of_household&.first_name
            e['last_name'] = head_of_household&.last_name

            e
          end

          expect(data).to eq(special_donation_hash)
        end
      end

      response(200, 'event_id and any_field query') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:any_field) { 'TT' }
        let(:date) {}
        let(:event_id) { 1 }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)

          @special_donations = Event.find_by_id(1).special_donations.where(home_number: 'TT520')
          special_donation_hash = @special_donations.as_json

          special_donation_hash = special_donation_hash.map do |e|
            head_of_household = SpecialDonation.find_by_id(e['id']).household.head_of_household
            e['name'] = head_of_household.full_name
            e['first_name'] = head_of_household.first_name
            e['last_name'] = head_of_household.last_name

            e
          end

          expect(data).to eq(special_donation_hash)
        end
      end

      response(401, 'unauthorized') do
        let(:authorization) { 'Bearer error token' }
        let(:any_field) {}
        let(:date) {}
        let(:event_id) {}

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

    post('create special_donation') do
      tags 'Special Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :special_donation, in: :body, schema: {
        type: :object,
        required: %w[home_number]
      }

      request_body_example value: {
        event_id: 1,
        home_number: 'TT520',

        donation_at: Date.strptime('2023/7/2', '%Y/%m/%d'),
        donation_amount: 1000,

        receipt: true,

        comment: '測試用奉獻'
      }, name: 'test_donation', summary: 'Test donation create'

      response(201, 'Created') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:special_donation) { @example_test }

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

      response(201, 'Special home number added') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:special_donation) { @special_home_number_hash }

        run_test! do |response|
          data = JSON.parse(response.body)
          @created_special_donation = SpecialDonation.find_by_id(data['id'])

          @special_home_number_hash.each_key do |key|
            if key == :donation_at
              date_data = data[key.to_s]
              date_data = date_data.nil? ? nil : Date.strptime(data[key.to_s])

              expect(date_data).to eq(@special_home_number_hash[key])
              expect(date_data).to eq(@created_special_donation[key])
            else
              expect(data[key.to_s]).to eq(@special_home_number_hash[key])
              expect(data[key.to_s]).to eq(@created_special_donation[key])
            end
          end
        end
      end

      response(403, 'Current user dose not have permission') do
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

      response(422, 'SpecialDonation already exist test') do
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

      response(422, 'Home number is blank') do
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

  path '/api/special_donations/{_id}' do
    # You'll want to customize the parameter types...
    parameter name: '_id', in: :path, type: :string, description: '_id'

    get('show special_donation') do
      tags 'Special Donations'
      security [Bearer: {}]

      response(200, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @special_donation.id }

        run_test! do |response|
          data = JSON.parse(response.body)

          special_donation_hash = @special_donation.as_json

          expect(data).to eq(special_donation_hash)
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

    patch('update special_donation') do
      tags 'Special Donations'
      security [Bearer: {}]
      consumes 'application/json'
      parameter name: :special_donation, in: :body, schema: {
        type: :object
      }

      request_body_example value: {
        home_number: 'TT521',
        head_of_special_donation_id: 2
      }, name: 'test home number change', summary: 'Test special_donation update'

      response(204, 'No Content') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @special_donation.id }
        let(:special_donation) { { donation_at: Date.strptime('2023/7/9', '%Y/%m/%d'), donation_amount: 1000 } }

        run_test! do
          @special_donation_updated = SpecialDonation.find_by_id(@special_donation.id)
          expect(@special_donation_updated.donation_at).to eq(Date.strptime('2023/7/9', '%Y/%m/%d'))
          expect(@special_donation_updated.donation_amount).to eq(1000)
        end
      end

      # Current user have not permission
      response(403, 'Forbidden') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @special_donation.id }
        let(:special_donation) { {} }

        run_test!
      end
    end

    delete('delete special_donation') do
      tags 'Special Donations'
      security [Bearer: {}]

      response(204, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'admin'}" }
        let(:_id) { @special_donation.id }

        run_test!
      end

      response(403, 'successful') do
        let(:authorization) { "Bearer #{authenticated_header 'viewer'}" }
        let(:_id) { @special_donation.id }

        run_test!
      end
    end
  end
end
