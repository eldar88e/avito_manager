class AddressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store, only: %i[show update destroy new create]
  before_action :set_address, only: %i[show update destroy]

  def show
    if @address
      render turbo_stream: [
        turbo_stream.replace("address_#{@address.id}", partial: 'addresses/address', locals: { address: @address })
      ]
    else
      error_notice(@address.errors.full_messages)
    end
  end

  def new
    @address = @store.addresses.build
    render turbo_stream: [
      turbo_stream.prepend(:addresses, partial: 'addresses/new', locals: { address: @address }),
      turbo_stream.remove(:new_address_btn)
    ]
  end

  def create
    @address = @store.addresses.build(address_params)
    return handle_successful_save if @address.save

    error_notice(@address.errors.full_messages)
  end

  def update
    return handle_successful_update if @address.update(address_params)

    error_notice(@address.errors.full_messages)
  end

  def destroy
    if @address.destroy
      msg = t('controllers.address', city: @address.city)
      render turbo_stream: [turbo_stream.remove("address_#{@address.id}"), success_notice(msg)]
    else
      error_notice(@address.errors.full_messages)
    end
  end

  private

  def set_address
    @address = @store.addresses.find(params[:id])
  end

  def address_params
    params.require(:address).permit(:city, :slogan, :slogan_params, :active, :image, :description, :total_games)
  end

  def handle_successful_save
    msg = ["Город #{@address.city} был успешно добавлен."]
    msg << 'Внимание адрес не активен!' if address_params[:active].to_i.zero?
    render turbo_stream: [
      turbo_stream.append(:addresses, partial: 'addresses/address', locals: { address: @address }),
      turbo_stream.remove(:new_address),
      turbo_stream.before(:addresses, partial: 'addresses/new_address_btn', locals: { store: @store }),
      success_notice(msg)
    ]
  end

  def handle_successful_update
    msg = ["Город #{@address.city} был успешно обновлен."]
    msg << 'Внимание адрес не активен!' if address_params[:active].to_i.zero?
    render turbo_stream: [
      turbo_stream.replace("address_#{@address.id}", partial: 'addresses/address', locals: { address: @address }),
      success_notice(msg)
    ]
  end
end
