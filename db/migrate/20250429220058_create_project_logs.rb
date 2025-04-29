class CreateProjectLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :project_logs do |t|
      t.references :project, foreign_key: true
      t.references :user, foreign_key: true
      t.string :level, null: false, default: 'info'
      t.string :source, null: false
      t.text :message, null: false
      t.text :details
      t.json :metadata
      t.string :tag
      t.datetime :logged_at, null: false

      t.timestamps
    end

    add_index :project_logs, :level
    add_index :project_logs, :source
    add_index :project_logs, :tag
    add_index :project_logs, :logged_at
  end
end
