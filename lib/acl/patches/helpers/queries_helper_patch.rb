module Acl::Patches::Helpers
  module QueriesHelperPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :column_content, :acl
      end
    end

    module InstanceMethods
      def column_content_with_acl(column, issue)
        res = column_content_without_acl(column, issue)
        if column.is_a?(QueryCustomFieldColumn) && (value = column.value_object(issue)).is_a?(CustomFieldValue) && value.acl_trimmed_size.to_i > 3 && value.custom_field.acl_trim_multiple?
          res << '&nbsp;&nbsp;'.html_safe
          res << link_to("<span>#{l(:label_acl_custom_field_all_trimmed, count: value.acl_trimmed_size.to_i)}</span>".html_safe, { controller: :issues, action: :acl_cf_trimmed_all, id: issue.id, cf_id: value.custom_field.id }, class: 'in_link link_to_modal click_out', id: "lb-cf-other-trimmed-#{issue.id}-#{value.custom_field.id}")
        end
        res
      end
    end
  end
end