class AssessmentsController < ApplicationController
  before_action :require_instructor
  before_action :set_course
  before_action :set_assessment, only: %i[edit update destroy]
  def new
    @assessment = @course.assessments.new
  end
  def create
    @assessment = @course.assessments.new(assessment_params)
    saved = @course.with_lock { @assessment.save }
    if saved
      redirect_to @course, notice: "Assessment added."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    saved = @course.with_lock { @assessment.update(assessment_params) }
    if saved
      redirect_to @course, notice: "Assessment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    removed = @course.with_lock { @assessment.destroy }
    redirect_to @course, **(removed ? { notice: "Assessment deleted." } : { alert: @assessment.errors.full_messages.to_sentence }), status: :see_other
  end

  private
  def set_course = @course = Course.find(params[:course_id])
  def set_assessment = @assessment = @course.assessments.find(params[:id])
  def assessment_params = params.require(:assessment).permit(:title, :weight)
end
