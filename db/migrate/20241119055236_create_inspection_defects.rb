class CreateInspectionDefects < ActiveRecord::Migration[7.2]
  def change
    create_table :inspection_defects do |t|
      t.belongs_to :quality_inspection, null: false, foreign_key: true
      t.text :description, null: false
      t.string :severity, null: false
      t.text :corrective_action

      t.timestamps
    end
  end
end
