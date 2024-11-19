class CreateMaterialCertificateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :material_certificate_items do |t|
      t.references :material_certificate, null: false, foreign_key: true
      t.references :delivery_item, null: false, foreign_key: true

      t.timestamps
    end

    add_index :material_certificate_items,
              [:material_certificate_id, :delivery_item_id],
              unique: true,
              name: 'index_material_certificate_items_unique'
  end
end
