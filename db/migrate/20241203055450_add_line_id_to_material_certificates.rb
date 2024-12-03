class AddLineIdToMaterialCertificates < ActiveRecord::Migration[7.2]
  def change
    add_column :material_certificates, :line_id, :string
  end
end
