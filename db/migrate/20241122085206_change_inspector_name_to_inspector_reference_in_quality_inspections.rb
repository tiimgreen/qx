class ChangeInspectorNameToInspectorReferenceInQualityInspections < ActiveRecord::Migration[7.2]
  def change
    remove_column :quality_inspections, :inspector_name
    add_reference :quality_inspections, :inspector, foreign_key: { to_table: :users }
  end
end
