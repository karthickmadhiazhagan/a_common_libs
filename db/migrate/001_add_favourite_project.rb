class AddFavouriteProject < ActiveRecord::Migration[4.2]

  def self.up
    # compatibility with usability
    unless UserPreference.column_names.include?('favourite_project_id')
      add_column :user_preferences, :favourite_project_id, :integer
    end
  end

  def self.down
    remove_column :user_preferences, :favourite_project_id
  end

end