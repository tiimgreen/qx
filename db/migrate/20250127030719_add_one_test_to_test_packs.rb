class AddOneTestToTestPacks < ActiveRecord::Migration[7.2]
  def change
    add_column :test_packs, :one_test, :boolean, default: false
  end
end
