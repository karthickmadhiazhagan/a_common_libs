# must be last in patches stack
module Acl::IssueQueryPatch
  def self.included(base)
    base.send :include, InstanceMethods

    base.class_eval do
      cattr_accessor :acl_stored_filter_types
      alias_method_chain :add_available_filter, :acl
      alias_method_chain :type_for, :acl
      alias_method_chain :sql_for_custom_field, :acl
      alias_method_chain :group_by_column, :acl
      alias_method_chain :sort_clause, :acl
    end
  end

  module InstanceMethods
    def add_available_filter_with_acl(field, options)
      if field.present? && options[:type].present?
        if self.class.acl_stored_filter_types.blank?
          self.class.acl_stored_filter_types = {}
        end
        self.class.acl_stored_filter_types[field.to_s] = options[:type]
      end
      add_available_filter_without_acl(field, options)
    end

    def type_for_with_acl(field)
      if self.class.acl_stored_filter_types && self.class.acl_stored_filter_types[field.to_s].present?
        self.class.acl_stored_filter_types[field.to_s]
      else
        type_for_without_acl(field)
      end
    end

    def sql_for_custom_field_with_acl(field, operator, value, custom_field_id)
      if @available_filters.blank?
        @available_filters ||= ActiveSupport::OrderedHash.new
        @available_filters[field] = { field: CustomField.find_by_id(custom_field_id) }
        return nil if @available_filters[field][:field].blank?

        res = sql_for_custom_field_without_acl(field, operator, value, custom_field_id)
        @available_filters = nil
      else
        res = sql_for_custom_field_without_acl(field, operator, value, custom_field_id)
      end
      res
    end

    def group_by_column_with_acl
      if group_by.present?
        group_by_column_without_acl
      else
        nil
      end
    end

    def sort_clause_with_acl
      if self.sort_criteria.blank?
        nil
      elsif self.sort_criteria.size == 1 && self.sort_criteria.first_key == 'id'
        ["#{Issue.table_name}.id #{self.sort_criteria.first_asc? ? 'ASC' : 'DESC'}"]
      else
        sort_clause_without_acl
      end
    end
  end
end