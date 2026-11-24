class ProfilesController < ApplicationController
  before_action :require_instructor
  def edit
    @user = current_user
  end
  def update
    @user = current_user
    attributes = params.require(:user).permit(:name, :surname, :email, :password, :password_confirmation).to_h
    attributes.except!("password", "password_confirmation") if attributes["password"].blank?
    if @user.update(attributes)
      redirect_to edit_profile_path, notice: "Your profile has been updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
