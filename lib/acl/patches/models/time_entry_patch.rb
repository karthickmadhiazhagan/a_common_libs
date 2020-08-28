module Acl::Patches::Models
  module TimeEntryPatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'custom_field_values_append', 'custom_field_values_delete'
      end
    end
  end
end