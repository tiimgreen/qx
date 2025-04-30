class AddQrPositionToDocuvitaDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :docuvita_documents, :qr_position, :string
  end
end
