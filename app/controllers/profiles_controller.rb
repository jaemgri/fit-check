class ProfilesController < ApplicationController
  def show
  end

  def update
    current_user.update!(profile_params)
    redirect_to profile_path, notice: "Profile updated."
  end

  private

  def profile_params
    params.require(:user).permit(:profile_photo, :base_photo)
  end
end
