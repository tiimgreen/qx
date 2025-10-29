class AddVtPicturesToIsometries < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :vt_pictures, :integer
  end
end
