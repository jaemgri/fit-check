class TryonsController < ApplicationController
  def index
    @tryons = current_user.tryons.order(created_at: :desc)
    @tryons = @tryons.where(favorite: true) if params[:filter] == "favorites"
  end

  def new
    @tryon = current_user.tryons.new
  end

  def create
    @tryon = current_user.tryons.new(tryon_params)

    if params[:person_photo_source] == "saved" && current_user.base_photo.attached?
      @tryon.person_photo.attach(current_user.base_photo.blob)
    end

    if @tryon.save
      if params[:save_as_base_photo] == "1" && @tryon.person_photo.attached?
        current_user.base_photo.attach(@tryon.person_photo.blob)
      end

      @tryon.update!(status: "processing")
      TryonGenerationJob.perform_later(@tryon)
      redirect_to tryon_path(@tryon)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @tryon = current_user.tryons.find(params[:id])
  end

  def destroy
    @tryon = current_user.tryons.find(params[:id])
    @tryon.destroy
    redirect_to tryons_path, notice: "Try-on deleted."
  end

  def regenerate
    @tryon = current_user.tryons.find(params[:id])
    @tryon.result_images.each(&:purge)
    @tryon.update!(status: "processing", error_message: nil)
    TryonGenerationJob.perform_later(@tryon)
    redirect_to tryon_path(@tryon)
  end

  def toggle_favorite
    @tryon = current_user.tryons.find(params[:id])
    @tryon.update!(favorite: !@tryon.favorite?)
    redirect_back fallback_location: tryons_path
  end

  private

  def tryon_params
    params.require(:tryon).permit(:name, :person_photo, clothing_photos: [])
  end
end
