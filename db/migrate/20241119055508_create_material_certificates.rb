class CreateMaterialCertificates < ActiveRecord::Migration[7.2]
  def change
    create_table :material_certificates do |t|
      t.belongs_to :project, null: false, foreign_key: true
      t.string :certificate_number, null: false
      t.string :batch_number, null: false
      t.date :issue_date, null: false
      t.string :issuer_name
      t.text :description

      t.timestamps
    end

    add_index :material_certificates, :certificate_number, unique: true
    add_index :material_certificates, :batch_number
  end
end
