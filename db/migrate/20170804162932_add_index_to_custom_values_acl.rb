class AddIndexToCustomValuesAcl < ActiveRecord::Migration[4.2]
  def change
    add_index :custom_values, [:customized_type, :customized_id, :custom_field_id], name: 'index_custom_values_ccc', unique: false
  end
end