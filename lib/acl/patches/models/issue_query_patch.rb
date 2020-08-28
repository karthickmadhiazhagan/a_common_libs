module Acl::Patches::Models
  module IssueQueryPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.class_eval do
        alias_method_chain :issues, :acl
      end
    end

    module InstanceMethods
      # must be last in alias_method_chain call stack, eg. first defined
      def issues_with_acl(options={})
        order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
        scope = Issue.visible.
            joins([:status, :project] + (options[:joins] || [])).
            preload([:priority] + (options[:preload] || [])).
            where(statement).
            includes(([:status, :project] + (options[:include] || [])).uniq).
            where(options[:conditions]).
            order(order_option).
            joins(joins_for_order_statement(order_option.join(','))).
            limit(options[:limit]).
            offset(options[:offset])

        scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))

        # problem: long preloading custom_values which contains over 1000 values for custom fields
        # solve: preload first N records for custom field based by "acl_trim_multiple" flag
        issues = acl_issues_with_preloaded_custom_fields(scope)

        if has_column?(:spent_hours)
          Issue.load_visible_spent_hours(issues)
        end
        if has_column?(:total_spent_hours)
          Issue.load_visible_total_spent_hours(issues)
        end
        if has_column?(:last_updated_by)
          Issue.load_visible_last_updated_by(issues)
        end
        if has_column?(:relations)
          Issue.load_visible_relations(issues)
        end
        if has_column?(:last_notes)
          Issue.load_visible_last_notes(issues)
        end
        issues
      rescue ::ActiveRecord::StatementInvalid => e
        raise Query::StatementInvalid.new(e.message)
      end

      private

      def acl_issues_with_preloaded_custom_fields(scope)
        if [:mysql, :mysql2, :postgresql, :sqlserver].include?(Issue.connection.adapter_name.downcase.to_sym)
          issues = scope.to_a
          return issues if issues.blank?

          # detect list of CFs to display
          query_cfs = self.columns.select { |column| column.class <= QueryCustomFieldColumn }
          if (grp_column = self.group_by_column).present? && grp_column.class <= QueryCustomFieldColumn
            query_cfs << grp_column
          end
          query_cfs = query_cfs.map { |c| c.custom_field }
          return issues if query_cfs.blank?

          Issue.acl_load_custom_values(issues, query_cfs)
        else
          if self.has_custom_field_column?
            scope = scope.preload(:custom_values)
          end
          issues = scope.to_a
        end

        issues
      end
    end
  end
end