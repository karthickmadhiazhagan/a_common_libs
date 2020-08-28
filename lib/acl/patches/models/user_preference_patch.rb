module Acl::Patches::Models
  module UserPreferencePatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'favourite_project_id'
      end
    end
  end
end