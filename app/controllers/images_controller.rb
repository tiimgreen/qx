# app/controllers/images_controller.rb
class ImagesController < ApplicationController
  layout "dashboard_layout"
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_edit!

  def destroy
    begin
      # delete the image fix
      model_class = if params[:model_type].downcase == "finalinspection"
        "FinalInspection"
      elsif params[:model_type].downcase == "workpreparation"
        "WorkPreparation"
      elsif params[:model_type].downcase == "sitedelivery"
        "SiteDelivery"
      elsif params[:model_type].downcase == "siteassembly"
        "SiteAssembly"
      elsif params[:model_type].downcase == "onsite"
        "OnSite"
      elsif params[:model_type].downcase == "testpack"
        "TestPack"
      elsif params[:model_type].downcase == "prewelding"
        "PreWelding"
      else
        params[:model_type].underscore.camelize
      end

      model = model_class.constantize.find(params[:model_id])

      # Ensure the model belongs to the current project
      unless model.project_id == @project.id
        Rails.logger.error "Unauthorized: Model #{params[:model_id]} does not belong to project #{@project.id}"
        return head :unauthorized
      end

      image_type = params[:image_type]
      image_id = params[:image_id]

      Rails.logger.info "Attempting to delete image: #{image_type} #{image_id} from #{model_class} #{model.id}"
      # Get the attachments collection based on image type
      attachments = case model_class.to_s
      when "Isometry"
        case image_type
        when "rt"
          model.rt_images
        when "vt"
          model.vt_images
        when "pt"
          model.pt_images
        when "on_hold"
          model.on_hold_images
        end
      when "Prefabrication", "WorkPreparation", "SiteAssembly", "OnSite", "TestPack", "PreWelding"
        case image_type
        when "on_hold"
          model.on_hold_images
        end
      when "FinalInspection"
        case image_type
        when "on_hold"
          model.on_hold_images
        when "visual_check"
          model.visual_check_images
        when "vt2_check"
          model.vt2_check_images
        when "pt2_check"
          model.pt2_check_images
        when "rt_check"
          model.rt_check_images
        end
      when "Transport", "SiteDelivery"
        case image_type
        when "check_spools"
          model.check_spools_images
        end
      else
        Rails.logger.error "Invalid model type: #{model_class}"
        return head :unprocessable_entity
      end

      # Find the specific attachment by blob ID
      if attachments
        attachment = attachments.attachments.find { |a| a.blob.signed_id == image_id }

        if attachment
          Rails.logger.info "Found attachment, attempting to purge"
          attachment.purge
          head :ok
        else
          Rails.logger.error "Attachment not found for signed_id: #{image_id}"
          head :not_found
        end
      else
        Rails.logger.error "Invalid image type: #{image_type}"
        head :unprocessable_entity
      end

    rescue => e
      Rails.logger.error "Error deleting image: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      head :internal_server_error
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_edit!
    unless current_user.can_edit?("Project")
      Rails.logger.error "User #{current_user.id} unauthorized to edit project #{@project.id}"
      head :unauthorized
    end
  end
end
