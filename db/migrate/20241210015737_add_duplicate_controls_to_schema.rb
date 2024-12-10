class AddDuplicateControlsToSchema < ActiveRecord::Migration[7.2]
  def change
    # Add duplicate fields with '1' suffix
    add_column :weldings, :component1, :string
    add_column :weldings, :dimension1, :string
    add_column :weldings, :material1, :string
    add_column :weldings, :batch_number1, :string
    add_column :weldings, :material_certificate1_id, :integer
    add_column :weldings, :type_code1, :string
    add_column :weldings, :wps1, :string
    add_column :weldings, :process1, :string
    add_column :weldings, :welder1, :string
    add_column :weldings, :rt_date1, :datetime
    add_column :weldings, :pt_date1, :datetime
    add_column :weldings, :vt_date1, :datetime
    add_column :weldings, :result1, :string

    # Add foreign key constraint for material_certificate1_id
    add_foreign_key :weldings, :material_certificates, column: :material_certificate1_id

    # Add index for material_certificate1_id
    add_index :weldings, :material_certificate1_id
  end
end
