class AclIncreaseSessionStore < ActiveRecord::Migration[4.2]
  def up
    change_column :sessions, :data, :text, limit: 16777214
  end
end