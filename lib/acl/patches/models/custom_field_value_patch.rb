module Acl::Patches::Models
  module CustomFieldValuePatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :value_was, :acl
        alias_method_chain :value, :acl
        alias_method_chain :value=, :acl

        attr_accessor :acl_changed, :acl_value, :acl_trimmed_size
        attr_accessor :acl_append, :acl_delete
      end
    end

    module InstanceMethods
      def value_with_acl
        return value_without_acl if @value_init

        @value_init = true
        if self.customized.present?
          if self.custom_field.multiple?
            values = self.customized.custom_values.select { |v| v.custom_field_id == self.custom_field.id }
            if values.empty?
              values << self.customized.custom_values.build(customized: self.customized, custom_field: self.custom_field)
            end
            @acl_value = {}
            vl = []
            values.each do |p|
              if p.value.present?
                @acl_value[p.value] = p.id
                vl << p.value
              end
            end
            @acl_trimmed_size ||= values.size
          else
            cv = self.customized.custom_values.detect { |v| v.custom_field == self.custom_field }
            cv ||= self.customized.custom_values.build(customized: self.customized, custom_field: self.custom_field)
            @acl_value = { cv.value => cv.id }
            vl = cv.value
            @acl_trimmed_size ||= 1
          end
          self.value_was = vl.dup if vl
          @value = vl
        end

        value_without_acl
      end

      def value_was_with_acl
        return value_was_without_acl if @value_init

        self.value
        value_was_without_acl
      end

      def value_with_acl=(vl, action='=', force=false)
        return if action != '=' && !self.custom_field.multiple?

        if self.custom_field.multiple?
          vl = Array.wrap(vl).select(&:present?)
        elsif vl.is_a?(Array)
          vl = vl.first
        end

        if force && !@value_init
          @value_init = true
          if self.custom_field.multiple?
            @acl_value = {}
            was_vl = []
            vl.each do |p|
              if p.value.present?
                @acl_value[p.value] = p.id
                was_vl << p.value
              end
            end
          else
            vl = vl.first if vl.is_a?(Array)
            @acl_value = {}
            was_vl = nil
            if vl.present?
              @acl_value = { vl.value => vl.id }
              was_vl = vl.value
            end
          end
          vl = was_vl
          self.value_was = vl.dup if vl
        elsif !@value_init
          self.value
        end

        if action == '='
          self.acl_changed = Array.wrap(self.value_was).to_set != Array.wrap(vl).to_set
          # Rails.logger.debug "\n --------------------- #{self.custom_field.id}: [#{self.acl_changed.inspect}] #{self.value_was.inspect}; #{vl.inspect}"
          send :value_without_acl=, vl
        else
          value = Array.wrap(vl)
          value = value.first unless self.custom_field.multiple?
          value = Array.wrap(self.custom_field.set_custom_field_value(self, value)).select(&:present?)

          return value if value.blank?
          if action == '+'
            @acl_append ||= []
            @acl_append = (@acl_append + value).uniq
            value = (self.value + value).uniq
          elsif action == '-'
            @acl_delete ||= []
            @acl_delete = (@acl_delete + value).uniq
            value = self.value - value
          end

          self.acl_changed = Array.wrap(self.value_was).to_set != Array.wrap(value).to_set
          send :value_without_acl=, value
        end
      end

      def cast_value(customized=nil)
        self.custom_field.format.cast_value(self.custom_field, self.value, customized)
      end

      def acl_save
        return true unless self.acl_changed

        self.acl_changed = false

        skip_full_update = false
        if self.acl_append.present?
          self.acl_append.each do |v|
            v = CustomValue.where(customized: self.customized, custom_field: self.custom_field, value: v).first_or_initialize({})
            v.save
          end
          skip_full_update = true
          self.acl_append = []
        end

        if self.acl_delete.present?
          CustomValue.where(customized: self.customized, custom_field_id: self.custom_field.id)
              .where(value: self.acl_delete)
              .delete_all
          skip_full_update = true
          self.acl_delete = []
        end

        return true if skip_full_update

        to_keep = []
        if self.value.is_a?(Array)
          self.value.each do |v|
            if self.acl_value.present? && self.acl_value[v].present?
              to_keep << self.acl_value[v]
            else
              v = CustomValue.new(customized: self.customized, custom_field: self.custom_field, value: v)
              v.save
              to_keep << v.id
            end
          end

          CustomValue.where(customized: self.customized, custom_field_id: self.custom_field.id)
              .where('id not in (?)', to_keep + [0])
              .delete_all
        else
          target = self.customized.custom_values.detect { |cv| cv.custom_field_id == self.custom_field.id }
          target ||= self.customized.custom_values.build(customized: self.customized, custom_field: self.custom_field)
          target.value = self.value
          target.save

          CustomValue.where(customized: self.customized, custom_field_id: self.custom_field.id)
              .where('id not in (?)', [target.id])
              .delete_all
        end
        true
      end
    end
  end
end