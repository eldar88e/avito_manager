class MapsController < ApplicationController
  before_action :authenticate_user!, :set_store, :set_address

  def show
    return error_notice('Error getting address') if @address.nil?

    @all_store = current_user.stores.active.includes(:addresses).where(addresses: { active: true }) if params[:all]
    render turbo_stream: [
      turbo_stream.replace("address_#{@address.id}", partial: '/maps/map', locals: { address: @address })
    ]
  end

  private

  def set_address
    @address = @store.addresses.find(params[:address_id]) if @store
  end
end
