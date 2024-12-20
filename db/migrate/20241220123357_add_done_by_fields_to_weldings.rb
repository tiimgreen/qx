class AddDoneByFieldsToWeldings < ActiveRecord::Migration[7.2]
  def change
    add_column :weldings, :rt_done_by, :string
    add_column :weldings, :pt_done_by, :string
    add_column :weldings, :vt_done_by, :string
    add_column :weldings, :rt_done_by1, :string
    add_column :weldings, :pt_done_by1, :string
    add_column :weldings, :vt_done_by1, :string
  end
end
