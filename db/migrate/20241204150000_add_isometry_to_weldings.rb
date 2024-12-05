class AddIsometryToWeldings < ActiveRecord::Migration[7.0]
  def change
    add_reference :weldings, :isometry, null: true, foreign_key: true
  end
end
