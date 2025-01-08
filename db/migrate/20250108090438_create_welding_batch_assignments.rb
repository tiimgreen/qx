class CreateWeldingBatchAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :welding_batch_assignments do |t|
      t.references :work_preparation, null: false, foreign_key: true
      t.references :welding, null: false, foreign_key: true
      t.string :batch_number
      t.string :batch_number1
      t.references :material_certificate, foreign_key: true
      t.references :material_certificate1, foreign_key: { to_table: :material_certificates }

      t.timestamps
    end

    # Add an index to ensure we don't have duplicate weldings for a work preparation
    add_index :welding_batch_assignments, [:work_preparation_id, :welding_id], unique: true, name: 'index_welding_assignments_on_work_prep_and_welding'
  end
end
