class RemoveQualityInspections < ActiveRecord::Migration[7.2]
  def change
    drop_table :inspection_defects, if_exists: true
    drop_table :quality_inspections, if_exists: true
  end
end
