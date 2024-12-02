class CreateIsometryDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :isometry_documents do |t|
      t.references :isometry, null: false, foreign_key: true
      t.string :qr_position
      t.timestamps
    end
  end
end
