class IsometryPageCreator
  def initialize(isometry)
    @isometry = isometry
  end

  def create_new_page
    ActiveRecord::Base.transaction do
      new_isometry = @isometry.dup
      # Get current number of pages for this line_id and revision
      current_pages = @isometry.class.where(
        project_id: @isometry.project_id,
        line_id: @isometry.line_id,
        revision_last: true,
        deleted: false
      ).count

      new_isometry.page_number = current_pages + 1
      new_isometry.page_total = @isometry.page_total
      new_isometry.revision_number = @isometry.revision_number
      new_isometry.revision_last = @isometry.revision_last

      copy_technical_specs(new_isometry)
      copy_additional_specs(new_isometry)

      new_isometry.save!
      new_isometry
    end
  end

  private

  def copy_technical_specs(new_isometry)
    new_isometry.received_date = @isometry.received_date
    new_isometry.pid_number = @isometry.pid_number
    new_isometry.pid_revision = @isometry.pid_revision
    new_isometry.line_id = @isometry.line_id
    new_isometry.dn = @isometry.dn
  end

  def copy_additional_specs(new_isometry)
    new_isometry.dp = @isometry.dp
    new_isometry.dip = @isometry.dip
    new_isometry.gmp = @isometry.gmp
    new_isometry.gdp = @isometry.gdp
    new_isometry.isolation_required = @isometry.isolation_required
    new_isometry.ped_category = @isometry.ped_category
    new_isometry.slope_if_needed = @isometry.slope_if_needed
    new_isometry.rt = @isometry.rt
    new_isometry.vt2 = @isometry.vt2
    new_isometry.pt2 = @isometry.pt2
    new_isometry.vt_pictures = @isometry.vt_pictures
  end
end
