class AddIsometryReferencesToSectorModels < ActiveRecord::Migration[7.2]
  def change
    add_reference :work_preparations, :isometry, null: true, foreign_key: true
    add_reference :prefabrications, :isometry, null: true, foreign_key: true
    add_reference :final_inspections, :isometry, null: true, foreign_key: true
    add_reference :transports, :isometry, null: true, foreign_key: true
    add_reference :site_deliveries, :isometry, null: true, foreign_key: true
    add_reference :site_assemblies, :isometry, null: true, foreign_key: true
    add_reference :on_sites, :isometry, null: true, foreign_key: true
    add_reference :test_packs, :isometry, null: true, foreign_key: true
    add_reference :pre_weldings, :isometry, null: true, foreign_key: true
    add_reference :incoming_deliveries, :isometry, null: true, foreign_key: true
  end
end
