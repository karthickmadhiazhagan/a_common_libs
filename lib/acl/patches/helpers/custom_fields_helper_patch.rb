module Acl::Patches::Helpers
  module CustomFieldsHelperPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :show_value, :acl
      end
    end

    module InstanceMethods
      def show_value_with_acl(custom_value, html=true)
        return show_value_without_acl(custom_value, html) unless html

        trimmed = false
        before_trim_size = 0
        original_values = nil
        if custom_value.is_a?(CustomFieldValue) &&
            custom_value.custom_field.present? &&
            custom_value.custom_field.format.present? &&
            custom_value.custom_field.format.multiple_supported &&
            custom_value.custom_field.multiple &&
            custom_value.custom_field.acl_trim_multiple? &&
            (original_values = custom_value.value.clone).present? &&
            custom_value.value.is_a?(Array) &&
            (before_trim_size = custom_value.value.size) > 3

          trimmed = true
          custom_value.value = custom_value.value[0..2]
        end

        res = show_value_without_acl(custom_value, html)

        if trimmed
          custom_value.value = original_values if original_values
          res << '&nbsp;&nbsp;'.html_safe
          res << link_to("<span>#{l(:label_acl_custom_field_all_trimmed, count: before_trim_size)}</span>".html_safe, { controller: :issues, action: :acl_cf_trimmed_all, id: custom_value.customized.id, cf_id: custom_value.custom_field.id }, class: 'in_link link_to_modal click_out', id: "lb-cf-other-trimmed-#{custom_value.customized.id}-#{custom_value.custom_field.id}")
        end

        res
      end
    end
  end
end

# class Module
#   def included(base)
#     @included_to ||= []
#     @included_to << base
#   end
#
#   def included_to
#     @included_to || []
#   end
# end

# module A
#   def a
#     puts "original"
#   end
# end
#
# class B
#   include A
#
#   def b
#     puts "b"
#   end
# end
#
# puts B
#
# module APatch
#   def self.included(base)
#     base.send :include, I
#     base.class_eval do
#       alias_method_chain :a, :a
#     end
#   end
#   module I
#     def a_with_a
#       puts "patched"
#       a_without_a
#     end
#   end
# end
#
# A.send :include, APatch