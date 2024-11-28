class RemoveMaterialCertificateItems < ActiveRecord::Migration[7.2]
  def change
    # Drop material_certificate_items table
    drop_table :material_certificate_items

    # Remove project_id from material_certificates
    remove_reference :material_certificates, :project, foreign_key: true
  end
end
