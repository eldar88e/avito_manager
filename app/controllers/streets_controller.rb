class StreetsController < ApplicationController
  before_action :authenticate_user!, :set_store, :set_address
  before_action :set_street, only: %i[update destroy]

  def index
    render turbo_stream: [
      turbo_stream.replace("address_#{@address.id}", partial: '/streets/streets_list', locals: { address: @address })
    ]
  end

  def create
    @street = @address.streets.build(title: params[:street][:title])
    return handle_successful_save if @street.save

    error_notice(@street.errors.full_messages)
  end

  def update
    return handle_successful_update if @street.update(title: params[:street][:title])

    error_notice(@street.errors.full_messages)
  end

  def destroy
    return handle_successful_destroy if @street.destroy

    error_notice(@street.errors.full_messages)
  end

  private

  def set_address
    @address = @store.addresses.find(params[:address_id]) if @store
  end

  def set_street
    @street = @address.streets.find(params[:id]) if @address
  end

  def handle_successful_save
    locals = { street: @street, method: :patch, url: store_street_path(id: @street, address_id: @address) }
    render turbo_stream: [
      turbo_stream.append("streets_#{params[:address_id]}", partial: 'streets/form', locals:),
      success_notice(t('controllers.streets.create', name: @street.title))
    ]
  end

  def handle_successful_update
    locals = { street: @street, method: :patch, url: store_street_path(id: @street, address_id: @address) }
    render turbo_stream: [
      turbo_stream.replace("street_#{@street.id}", partial: 'streets/form', locals:),
      success_notice(t('controllers.streets.update', name: @street.title))
    ]
  end

  def handle_successful_destroy
    render turbo_stream: [
      turbo_stream.remove(@street),
      success_notice(t('controllers.streets.destroy', name: @street.title))
    ]
  end
end
