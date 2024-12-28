class AddDraftToIsometries < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :draft, :boolean
  end
end
