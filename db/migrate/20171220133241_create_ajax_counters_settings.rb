class CreateAjaxCountersSettings < ActiveRecord::Migration[4.2]
  def change
    create_table :acl_ajax_counters do |t|
      t.string :token
      t.text :options
    end
  end
end