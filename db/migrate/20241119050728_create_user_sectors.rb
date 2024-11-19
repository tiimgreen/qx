class CreateUserSectors < ActiveRecord::Migration[7.2]
  def change
    create_table :user_sectors do |t|
      t.references :user, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true
      t.timestamps
    end

    add_index :user_sectors, [ :user_id, :sector_id ], unique: true
  end
end
