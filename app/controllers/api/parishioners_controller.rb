module Api
  class ParishionersController < ApplicationController
    before_action :authorize_request # , except: :index
    before_action :find_parishioner, except: %i[create index]

    # GET /parishioners
    # @todo change the
    def index
      authorize! :read, Parishioner
      @query = params[:any_field]

      if @query
        # TODO change to full text search

        puts "---"
        puts @query
        puts "---"
        @parishioners = Parishioner
                          .where(["name like ?  or
                                  comment like ? or
                                  father like ? or
                                  mother like ? or
                                  spouse like ?",
                                  "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%", "%#{@query}%"])
      else
        @parishioners = Parishioner.all
      end

      @parishioners = @parishioners
                        .select(*%w[
                          name gender birth_at postal_code address photo_url
                          father mother spouse father_id mother_id spouse_id
                          home_phone mobile_phone nationality
                          profession company_name comment
                        ])
                        .as_json(except: :id)

      render json: @parishioners, status: :ok
    end

    # GET /parishioners/{id}
    def show
      authorize! :read, @parishioner
      render json: @parishioner, status: :ok
    end

    # POST /parishioners
    # TODO upload image
    def create
      authorize! :create, Parishioner

      @parishioner = Parishioner.new(parishioner_params)
      if @parishioner.save
        render json: @parishioner, status: :created
      else
        render json: { errors: @parishioner.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # PUT /parishioners/{id}
    def update
      authorize! :update, @parishioner
      unless @parishioner.update(parishioner_params)
        render json: { errors: @parishioner.errors.full_messages },
               status: :unprocessable_entity
      end
    end

    # DELETE /parishioners/{id}
    def destroy
      authorize! :destroy, @parishioner

      @parishioner.destroy
    end

    private

    def find_parishioner
      @parishioner = Parishioner.find_by_id!(params[:_id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: 'Parishioner not found' }, status: :not_found
    end

    def parishioner_params
      # params.permit(
      #   :name, :gender, :birth_at, :postal_code, :address, :photo_url,
      #   :father, :mother, :spouse, :home_phone, :mobile_phone, :nationality,
      #   :profession, :company_name, :comment
      # )
      params.permit(%i[
                          name gender birth_at postal_code address photo_url
                          father mother spouse home_phone mobile_phone nationality
                          profession company_name comment
      ])

    end

    def current_policy
      @current_policy ||= ::AccessPolicy.new(@current_user)
    end
  end
end