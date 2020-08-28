class AddAjaxableToCustomFields < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_fields, :ajaxable, :boolean, default: false
  end
end