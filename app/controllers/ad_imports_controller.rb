class AdImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ad_imports, only: %i[show destroy]
  # add_breadcrumb 'Главная', :root_path

  def index
    # add_breadcrumb 'Игры'
    @pagy, @ad_imports = pagy(@q.result, items: 12)
  end

  def show
    # add_breadcrumb 'Игры', ad_imports_path
    # add_breadcrumb @ad_imports.name
    @ads = @ad_imports.ads.includes(image_attachment: :blob)
  end

  def destroy
    @ad_imports.destroy
    flash[:notice] = "Объявление #{@ad_imports.name} было успешно удалено."
    redirect_to ad_imports_path
  end

  private

  def set_ad_imports
    @ad_imports = AdImport.find(params[:id])
  end
end
