class AvitosController < ApplicationController
  before_action :authenticate_user!

  def index
    @stores = current_user.stores.order(:created_at)
  end
end
