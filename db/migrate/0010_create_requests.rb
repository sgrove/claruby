class CreateRequests < ActiveRecord::Migration
  def self.up
    create_table :requests do |t|
      t.string :environment
      t.string :controller
      t.string :action
      t.string :ip
      t.datetime :time
      t.string :http_method
      t.text :parameters
      t.integer :view_time
      t.integer :db_time
      t.string :http_response
      t.text :url
      t.string :embed_key
      t.string :permalink

      t.string :error
    end
  end

  def self.down
    drop_table :requests
  end
end
