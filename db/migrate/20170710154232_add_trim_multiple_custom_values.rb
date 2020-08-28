class AddTrimMultipleCustomValues < ActiveRecord::Migration[4.2]
  def up
    if ActiveRecord::Base.connection.column_exists?(:custom_fields, :lb_trim_multiple)
      rename_column :custom_fields, :lb_trim_multiple, :acl_trim_multiple
    else
      add_column :custom_fields, :acl_trim_multiple, :boolean
    end
  end

  def down
    remove_column :custom_fields, :acl_trim_multiple
  end
end