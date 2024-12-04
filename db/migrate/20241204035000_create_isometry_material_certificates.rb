class CreateIsometryMaterialCertificates < ActiveRecord::Migration[7.2]
  def change
    create_table :isometry_material_certificates do |t|
      t.references :isometry, null: false, foreign_key: true
      t.references :material_certificate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
