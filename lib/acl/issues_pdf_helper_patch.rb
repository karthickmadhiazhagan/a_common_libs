module Acl::IssuesPdfHelperPatch
  def self.included(base)
    base.send :include, InstanceMethods

    base.class_eval do
      alias_method_chain :fetch_row_values, :acl
    end
  end

  module InstanceMethods
    def fetch_row_values_with_acl(issue, query, level)
      query.inline_columns.collect do |column|
        s = if column.is_a?(QueryCustomFieldColumn)
          cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
          show_value(cv, false)
        else
          value = column.value_object(issue)
          case column.name
            when :subject
              value = "  " * level + value
            when :attachments
              value = value.to_a.map {|a| a.filename}.join("\n")
          end
          if value.is_a?(Date)
            format_date(value)
          elsif value.is_a?(Time)
            format_time(value)
          else
            format_object(value, false)
          end
        end
        s.to_s
      end
    end
  end
end

unless Redmine::Export::PDF::IssuesPdfHelper.included_modules.include?(Acl::IssuesPdfHelperPatch)
  Redmine::Export::PDF::IssuesPdfHelper.send :include, Acl::IssuesPdfHelperPatch
end