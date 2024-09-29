class MainController < ApplicationController
  def index
    render json: ApiResponse.new(payload: { "message": "salam" }).to_h, status: :ok
  end
end
