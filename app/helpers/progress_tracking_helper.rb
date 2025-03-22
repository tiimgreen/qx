module ProgressTrackingHelper
  def get_completed_items(project, work_type_sector, start_date)
    case work_type_sector.key.to_sym
    when :prefabrication
      project.isometries
        .joins(:prefabrication)
        .where.not(prefabrications: { completed: nil })
        .includes(:prefabrication)
    when :site_assembly
      project.site_assemblies
        .where.not(completed: nil)
    when :isometry
      project.isometries
        .where.not(received_date: nil)
        .where("received_date >= ?", start_date)
    when :work_preparation
      project.work_preparations
        .where.not(completed: nil)
    when :pre_welding
      project.pre_weldings
        .where.not(completed: nil)
    when :final_inspection
      project.final_inspections
        .where.not(completed: nil)
    when :transport
      project.transports
        .where.not(completed: nil)
    when :site_delivery
      project.site_deliveries
        .where.not(completed: nil)
    when :on_site
      project.on_sites
        .where.not(completed: nil)
    when :test_pack
      project.test_packs
        .where.not(completed: nil)
    end
  end

  def group_completed_items(items, work_type_sector, start_date)
    return {} if items.nil?

    items.group_by do |item|
      completed_date = case work_type_sector.key.to_sym
      when :prefabrication
        item.prefabrication.completed
      when :site_assembly, :work_preparation, :pre_welding, :final_inspection,
           :transport, :site_delivery, :on_site, :test_pack
        item.completed
      when :isometry
        item.received_date
      end
      "W%02d/%d" % [ completed_date.strftime("%V").to_i, start_date.year ]
    end
  end

  def calculate_ist_value(item, work_type_sector)
    case work_type_sector.key.to_sym
    when :prefabrication, :site_assembly, :work_preparation, :pre_welding,
         :transport, :site_delivery, :on_site
      # For items that track length
      item.respond_to?(:length) ? item.length : 0
    when :isometry, :final_inspection, :test_pack
      # For items that are counted as units
      1
    else
      0
    end
  end

  def progress_unit(work_type_sector)
    unit_key = case work_type_sector.key.to_sym
    when :prefabrication, :site_assembly, :work_preparation, :pre_welding,
         :transport, :site_delivery, :on_site
      # For items measured in meters
      "meters"
    when :isometry, :final_inspection, :test_pack
      # For items counted as pieces
      "pieces"
    else
      "pieces" # Default to pieces for unknown types
    end
    t("progress_tracking.units.#{unit_key}")
  end

  def format_week_display(week)
    week.split("/").first # This will take 'W01' from 'W01/2025'
  end
end
