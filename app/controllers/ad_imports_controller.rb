class AdImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ad_imports, only: %i[show destroy]
  # add_breadcrumb 'Главная', :root_path

  def index
    # add_breadcrumb 'Игры'
    ad_imports = current_user.ad_imports.order(created_at: :desc)
    @store = current_user.stores.active.find_by(id: params[:store_id]) || current_user.stores.active.first
    @pagy, @ad_imports = pagy(ad_imports, limit: 30)
  end

  def show
    # add_breadcrumb 'Игры', ad_imports_path
    # add_breadcrumb @ad_imports.title
    @ads = @ad_imports.ads.includes(image_attachment: :blob)
  end

  def destroy
    @ad_imports.destroy!
    msg = "Объявление #{@ad_imports.title} было успешно удалено."

    render turbo_stream: [turbo_stream.remove("ad_import_#{@ad_imports.id}"), success_notice(msg)]
  end

  private

  def set_ad_imports
    @ad_imports = current_user.ad_imports.find(params[:id])
  end
end
