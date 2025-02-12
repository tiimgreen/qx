class ProgressTrackingController < ApplicationController
  before_action :set_project
  before_action :set_progress_plan, only: [ :show, :update ]

  def index
    @progress_plans = @project.project_progress_plans.order(created_at: :desc)
  end

  def show
    @weekly_entries = @progress_plan.weekly_progress_entries.order(:year, :week_number)
  end

  def create
    @progress_plan = @project.project_progress_plans.build(progress_plan_params)

    if @progress_plan.save
      generate_weekly_entries
      redirect_to project_progress_tracking_path(@project, @progress_plan, locale: I18n.locale), notice: t(".success")
    else
      respond_to do |format|
        format.html do
          @progress_plans = @project.project_progress_plans.order(created_at: :desc)
          flash.now[:error] = @progress_plan.errors.full_messages.to_sentence
          render :index, status: :unprocessable_entity
        end
        format.json { render json: @progress_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    if params[:weekly_progress_entry].present?
      update_weekly_entry
    elsif @progress_plan.update(progress_plan_params)
      redirect_to project_progress_tracking_path(@project, @progress_plan, locale: I18n.locale), notice: t(".success")
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @progress_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  def chart_data
    @progress_plan = @project.project_progress_plans.find(params[:id])
    @weekly_entries = @progress_plan.weekly_progress_entries.order(:year, :week_number)

    render json: {
      labels: @weekly_entries.map { |entry| "W#{entry.week_number}/#{entry.year}" },
      expected: @weekly_entries.map(&:expected_value),
      actual: @weekly_entries.map(&:actual_value)
    }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_progress_plan
    @progress_plan = @project.project_progress_plans.find(params[:id])
  end

  def progress_plan_params
    params.require(:project_progress_plan).permit(:work_type, :start_date, :end_date)
  end

  def weekly_entry_params
    params.require(:weekly_progress_entry).permit(:expected_value, :actual_value)
  end

  def update_weekly_entry
    @entry = @progress_plan.weekly_progress_entries.find(params[:weekly_entry_id])

    if @entry.update(weekly_entry_params)
      respond_to do |format|
        format.html { redirect_to project_progress_tracking_path(@project, @progress_plan), notice: t(".entry_updated") }
        format.json { render json: @entry }
      end
    else
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  def generate_weekly_entries
    start_date = @progress_plan.start_date.to_date
    end_date = @progress_plan.end_date.to_date
    current_date = start_date

    while current_date <= end_date
      week = current_date.strftime("%V").to_i
      year = current_date.year

      @progress_plan.weekly_progress_entries.create(
        week_number: week,
        year: year
      )

      current_date += 1.week
    end
  end
end
