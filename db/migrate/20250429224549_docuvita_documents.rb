class DocuvitaDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :docuvita_documents do |t|
      t.references :documentable, polymorphic: true, null: false
      t.string :docuvita_object_id, null: false
      t.string :document_type, null: false
      t.string :filename
      t.string :content_type
      t.integer :byte_size
      t.string :checksum
      t.json :metadata

      t.timestamps
    end

    add_index :docuvita_documents, :docuvita_object_id
    add_index :docuvita_documents, :document_type
  end
end
