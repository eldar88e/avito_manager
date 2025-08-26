class StoresController < ApplicationController
  before_action :authenticate_user!
  before_action :set_store, only: %i[show edit update destroy]
  before_action :set_search_ads, only: :show
  # add_breadcrumb 'Главная', :root_path
  # before_action :set_breadcrumb, only: %i[index show new edit]

  def index
    @stores = current_user.stores.order(active: :desc).order(:created_at)
  end

  def show
    # add_breadcrumb @store.manager_name, store_path(@store)
    @pagy, @ads   = pagy(@q_ads.result, items: 36)
    @addresses    = @store.addresses.includes(:streets, image_attachment: :blob).order(:id)
    @image_layers = @store.image_layers.includes(layer_attachment: :blob).order(:menuindex, :id)
  end

  def new
    @store = current_user.stores.build
  end

  def edit; end

  def create
    @store = current_user.stores.build(store_params)

    if @store.save
      msg = ["Магазин #{@store.manager_name} был успешно добавлен."]
      msg << 'Внимание магазин не активен!' if store_params[:active].to_i.zero?
      flash[:success] = msg
      redirect_to @store
    else
      error_notice(@store.errors.full_messages)
    end
  end

  def update
    if @store.update(store_params)
      msg = ["Магазин #{@store.manager_name} был успешно обновлен."]
      msg << 'Внимание магазин не активен!' if store_params[:active].to_i.zero?
      flash[:success] = msg
      redirect_to @store
    else
      error_notice(@store.errors.full_messages)
    end
  end

  def destroy
    if @store.destroy
      msg = "Магазин #{@store.manager_name} был успешно удален."
      render turbo_stream: [turbo_stream.remove("store_#{@store.id}"), success_notice(msg)]
    else
      error_notice(@store.errors.full_messages)
    end
  end

  private

  def set_breadcrumb
    add_breadcrumb 'Аккаунты', stores_path
  end

  def store_params
    params.expect(
      store: %i[
        manager_name var ad_status category goods_type ad_type type desc_ad_import menuindex active contact_method
        description condition desc_product percent allow_email contact_phone img_params table_id client_id
        client_secret
      ]
    )
  end
end
