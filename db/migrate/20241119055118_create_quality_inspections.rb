class CreateQualityInspections < ActiveRecord::Migration[7.2]
  def change
    create_table :quality_inspections do |t|
      t.belongs_to :delivery_item, null: false, foreign_key: true
      t.string :inspection_type, null: false
      t.string :inspector_name, null: false
      t.string :status, null: false
      t.datetime :inspection_date, null: false
      t.text :notes

      t.timestamps
    end

    add_index :quality_inspections, :inspection_type
    add_index :quality_inspections, :status
  end
end
