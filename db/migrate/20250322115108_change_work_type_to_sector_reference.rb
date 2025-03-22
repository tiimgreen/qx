class ChangeWorkTypeToSectorReference < ActiveRecord::Migration[7.2]
  def up
    # Add new sector reference
    add_reference :project_progress_plans, :work_type_sector, foreign_key: { to_table: :sectors }

    # Migrate existing data
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE project_progress_plans
          SET work_type_sector_id = (
            CASE work_type
              WHEN 0 THEN (SELECT id FROM sectors WHERE key = 'isometry')
              WHEN 1 THEN (SELECT id FROM sectors WHERE key = 'prefabrication')
              WHEN 2 THEN (SELECT id FROM sectors WHERE key = 'site_assembly')
            END
          )
        SQL
      end
    end

    # Remove old column
    remove_column :project_progress_plans, :work_type
  end

  def down
    add_column :project_progress_plans, :work_type, :integer

    # Restore old data
    reversible do |dir|
      dir.down do
        execute <<-SQL
          UPDATE project_progress_plans
          SET work_type = (
            CASE#{' '}
              WHEN work_type_sector_id = (SELECT id FROM sectors WHERE key = 'isometry') THEN 0
              WHEN work_type_sector_id = (SELECT id FROM sectors WHERE key = 'prefabrication') THEN 1
              WHEN work_type_sector_id = (SELECT id FROM sectors WHERE key = 'site_assembly') THEN 2
            END
          )
        SQL
      end
    end

    remove_reference :project_progress_plans, :work_type_sector
  end
end
