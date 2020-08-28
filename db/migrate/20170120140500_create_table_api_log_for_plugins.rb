class CreateTableApiLogForPlugins < ActiveRecord::Migration[4.2]
  def change
    create_table :api_log_for_plugins do |t|
      t.text :plugin_code, null: false
      t.integer :error_code
      t.text :description
      t.text :controller
      t.text :action
      t.text :params
      t.integer :user_id
      t.boolean :served, null: false, default: false
      t.timestamps
    end
  end
end