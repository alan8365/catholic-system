# frozen_string_literal: true

module Api
  class EventsController < ApplicationController
    before_action :cors_setting
    before_action :authorize_request, except: %i[]
    before_action :find_event, except: %i[create index]

    # GET /events
    def index
      authorize! :read, Event

      query = params[:any_field] || ''
      date = params[:date] || ''

      page = if params[:page].present?
               params[:page]
             else
               '1'
             end
      per_page = if params[:per_page].present?
                   params[:per_page]
                 else
                   '10'
                 end

      page = page.to_i
      per_page = per_page.to_i

      non_page = ActiveRecord::Type::Boolean.new.cast(params[:non_page])

      @events = Event.all

      if date&.match?(/\d{4}/)
        year = date.to_i

        begin_date = Date.civil(year, 1, 1)
        end_date = Date.civil(year, 12, -1)

        @events = @events.where(start_at: begin_date..end_date)
      end

      unless query.empty?
        string_filed = %w[
          name
          comment
        ]

        query_string = string_filed.join(" like ? or \n")
        query_string += ' like ?'

        query_array = string_filed.map { |_| "%#{query}%" }.compact

        @events = @events.where([query_string, *query_array])
      end

      @events = @events
                .select(*%w[
                          id
                          name
                          start_at
                          comment
                        ])

      if non_page
        result = @events
        total_page = 1
      else
        result = @events.paginate(page:, per_page:)
        total_page = result.total_pages
      end

      result = result
               .as_json(
                 methods: :donation_count
               )

      render json: {
               data: result,
               total_page:
             },
             status: :ok
    end

    # GET /events/{id}
    def show
      authorize! :read, @event

      render json: @event, methods: :donation_count, status: :ok
    end

    # POST /events
    def create
      authorize! :create, Event

      create_params = event_params.to_h

      @event = Event.new(create_params)
      if @event.save
        render json: @event, status: :created
      else
        render json: { errors: @event.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /events/{id}
    def update
      authorize! :update, @event

      update_params = event_params.to_h

      return if @event.update(update_params)

      render json: { errors: @event.errors.full_messages },
             status: :unprocessable_entity
    end

    # DELETE /events/{id}
    def destroy
      authorize! :destroy, @event
      @event.destroy
    end

    private

    def find_event
      @event = Event.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: I18n.t('event_not_found') }, status: :not_found
    end

    def event_params
      params.permit(
        *%i[
          name
          start_at
          comment
        ]
      )
    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end
