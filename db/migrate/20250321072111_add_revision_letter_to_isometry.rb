class AddRevisionLetterToIsometry < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :revision_letter, :string
  end
end
