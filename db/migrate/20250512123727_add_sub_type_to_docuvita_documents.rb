class AddSubTypeToDocuvitaDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :docuvita_documents, :document_sub_type, :string
  end
end
