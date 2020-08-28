#  coding: utf-8
class CreateSessionStoreTable < ActiveRecord::Migration[4.2]

  def self.up
    unless ActiveRecord::Base.connection.table_exists? 'sessions'
      create_table :sessions do |t|
        t.string   :session_id
        t.text     :data

        t.timestamps
      end
    end
  end

  def self.down
    # not remove it
  end
end
