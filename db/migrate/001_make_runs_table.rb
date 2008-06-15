class MakeRunsTable < ActiveRecord::Migration
  def self.up             
    create_table :runs do |t|
      t.column :project, :string
      t.column :build, :string
      t.column :started, :timestamp
      t.column :finished, :timestamp
      t.column :status, :string, :default => 'running'
      t.column :log, :text
      t.column :revision, :integer
      t.column :committer, :string
      t.column :created_at, :timestamp
      t.column :updated_at, :timestamp
    end
  end

  def self.down                 
    drop_table :runs
  end
end
