class MainController < ApplicationController
  def index
    render json: ApiResponseGenerator.new(payload: { "message": 'salam' }).to_h, status: :ok
  end
end
