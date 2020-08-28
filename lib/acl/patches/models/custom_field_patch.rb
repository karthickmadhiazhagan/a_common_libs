module Acl::Patches::Models
  module CustomFieldPatch
    def self.included(base)
      base.class_eval do
        safe_attributes 'ajaxable', 'acl_trim_multiple'

        attr_accessor :acl_cf_casted_values
      end
    end
  end
end