module Acl::ActsAsCustomizablePatch
  def self.included(base)
    base.extend ClassMethods

    base.class_eval do
      class << self
        alias_method_chain :acts_as_customizable, :acl
      end
    end
  end

  module ClassMethods
    def acts_as_customizable_with_acl(options={})
      acts_as_customizable_without_acl(options)
      return if self.included_modules.include?(AclInstanceMethods)
      send :include, AclInstanceMethods
    end
  end

  module AclInstanceMethods
    def self.included(base)
      base.send :alias_method_chain, :custom_field_values=, :acl
      base.send :alias_method_chain, :custom_field_values, :acl
      base.send :alias_method_chain, :save_custom_field_values, :acl
      base.send :alias_method_chain, :custom_field_value, :acl
      base.send :alias_method_chain, :reassign_custom_field_values, :acl
      base.send :alias_method_chain, :reset_custom_values!, :acl
      base.send :alias_method_chain, :reload, :acl

      base.class_eval do
        attr_accessor :acl_cfv_hash
      end
    end

    def acl_available_custom_fields
      if @acl_available_custom_fields.present?
        @acl_available_custom_fields
      else
        res = self.available_custom_fields
        @acl_available_custom_fields = res.inject({}) { |h, it| h[it.id] = it; h }
      end
    end

    def acl_available_custom_fields=(vals)
      @acl_available_custom_fields = vals
    end

    def custom_field_values_with_acl
      @acl_cfv_hash ||= {}
      return @custom_field_values if @custom_field_values

      if @acl_available_custom_fields.present?
        cfv = @acl_available_custom_fields.values
      else
        cfv = self.available_custom_fields
      end
      @custom_field_values ||= cfv.map do |field|
        unless @acl_cfv_hash.has_key?(field.id.to_s)
          x = CustomFieldValue.new
          x.custom_field = field
          x.customized = self
          @acl_cfv_hash[field.id.to_s] = x
        end
        @acl_cfv_hash[field.id.to_s]
      end
      @custom_field_values
    end

    # in use by plugins
    def custom_field_value_by_id(field_id)
      @acl_cfv_hash = {} if @acl_cfv_hash.blank?
      return @acl_cfv_hash[field_id.to_s] if @acl_cfv_hash.has_key?(field_id.to_s)
      if self.acl_available_custom_fields.has_key?(field_id.to_i)
        x = CustomFieldValue.new
        x.custom_field = self.acl_available_custom_fields[field_id.to_i]
        x.customized = self
        @acl_cfv_hash[field_id.to_s] = x
        x
      else
        nil
      end
    end

    def custom_field_value_with_acl(c)
      field_id = (c.is_a?(CustomField) ? c.id : c.to_i)
      custom_field_value_by_id(field_id).try(:value)
    end

    def custom_field_values_with_acl=(values, action='=')
      values.stringify_keys.each do |(key, value)|
        cfv = self.custom_field_value_by_id(key)
        if cfv.present?
          cfv.send :value=, value, action
        end
      end

      @custom_field_values_changed = true
    end

    # in use by plugins
    def custom_field_values_append=(values)
      send :custom_field_values=, values, '+'
    end
    # in use by plugins
    def custom_field_values_delete=(values)
      send :custom_field_values=, values, '-'
    end

    def save_custom_field_values_with_acl
      (@acl_cfv_hash || {}).each do |(key, custom_field_value)|
        custom_field_value.acl_save
      end
      if @acl_cfv_hash.present? && @custom_field_values_changed
        self.custom_values.reload
      end
      @custom_field_values_changed = false
      true
    end

    def reassign_custom_field_values_with_acl
      @acl_cfv_hash = {}
      @acl_available_custom_fields = nil
      if @custom_field_values
        values = @custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
        @custom_field_values = nil
        self.custom_field_values = values
      end
    end

    def reset_custom_values_with_acl!
      reset_custom_values_without_acl!
      @acl_cfv_hash = {}
      @acl_available_custom_fields = nil
    end

    def reload_with_acl(*args)
      @acl_cfv_hash = {}
      @acl_available_custom_fields = nil
      reload_without_acl(*args)
    end
  end
end

unless ActiveRecord::Base.included_modules.include?(Acl::ActsAsCustomizablePatch)
  ActiveRecord::Base.send :include, Acl::ActsAsCustomizablePatch
end