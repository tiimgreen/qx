class CreateIsometries < ActiveRecord::Migration[7.2]
  def change
    create_table :isometries do |t|
      # Core attributes
      t.datetime :received_date
      t.string :on_hold_status
      t.string :on_hold_comment
      t.datetime :on_hold_date
      t.string :pid_number
      t.integer :pid_revision
      t.string :ped_category
      t.boolean :gmp, default: false
      t.boolean :gdp, default: false
      t.string :system

      # Technical specifications
      t.string :pipe_class
      t.string :material
      t.string :line_id
      t.integer :revision_number
      t.boolean :revision_last, default: true
      t.integer :page_number
      t.integer :page_total
      t.string :dn1
      t.string :dn2
      t.string :dn3
      t.string :medium

      # Measurements and tracking
      t.decimal :pipe_length, precision: 10, scale: 2
      t.integer :workshop_sn
      t.integer :assembly_sn
      t.integer :total_sn
      t.integer :total_supports
      t.integer :total_spools
      t.decimal :rt, precision: 5, scale: 2
      t.decimal :vt2, precision: 5, scale: 2
      t.decimal :pt2, precision: 5, scale: 2

      # Additional specifications
      t.boolean :dp, default: false
      t.boolean :dip, default: false
      t.string :slope_if_needed
      t.boolean :isolation_required, default: false
      t.integer :work_package_number
      t.integer :test_pack_number

      # References
      t.references :project, null: false, foreign_key: true
      t.references :sector, foreign_key: true
      t.references :user, foreign_key: true

      # Common fields
      t.text :notes
      t.boolean :deleted, default: false
      t.timestamps
    end

    # Add indexes for commonly searched fields
    add_index :isometries, :line_id, unique: true
    add_index :isometries, :pid_number
    add_index :isometries, :system
    add_index :isometries, :received_date

    # Add indexes for status and filtering
    add_index :isometries, :on_hold_status
    add_index :isometries, :deleted
    add_index :isometries, :revision_number
    add_index :isometries, :revision_last

    # Add indexes for work management
    add_index :isometries, :work_package_number
    add_index :isometries, :test_pack_number

    # Add compound indexes for common query patterns
    add_index :isometries, [ :project_id, :deleted ]
    add_index :isometries, [ :project_id, :on_hold_status ]
    add_index :isometries, [ :project_id, :system ]
    add_index :isometries, [ :project_id, :revision_last ]
  end
end
