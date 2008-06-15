class AddRepository < ActiveRecord::Migration
  def self.up                       
    add_column :runs, :repository, :string
  end

  def self.down     
    remove_column :runs, :repository
  end
end
