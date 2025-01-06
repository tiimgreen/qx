class AddPt2RtToFinalInspections < ActiveRecord::Migration[7.2]
  def change
    add_column :final_inspections, :pt2_check_status, :text
    add_column :final_inspections, :pt2_check_comment, :text
    add_column :final_inspections, :rt_check_status, :text
    add_column :final_inspections, :rt_check_comment, :text
  end
end
