module ProgressTrackingHelper
  def get_completed_items(project, work_type, start_date)
    case work_type.to_sym
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
        .where.not(approved_at: nil)
        .where('approved_at >= ?', start_date)
    end
  end

  def group_completed_items(items, work_type, start_date)
    items.group_by do |item|
      completed_date = case work_type.to_sym
      when :prefabrication
        item.prefabrication.completed
      when :site_assembly
        item.completed
      when :isometry
        item.approved_at
      end
      "W%02d/%d" % [completed_date.strftime('%V').to_i, start_date.year]
    end
  end

  def calculate_ist_value(item, work_type)
    case work_type.to_sym
    when :prefabrication
      item.pipe_length.to_f
    when :site_assembly
      item.isometry&.pipe_length.to_f || 0
    when :isometry
      1 # Count each isometry as 1
    end
  end

  def progress_unit(work_type)
    case work_type.to_sym
    when :prefabrication, :site_assembly
      'm'
    when :isometry
      'pcs'
    end
  end
end
