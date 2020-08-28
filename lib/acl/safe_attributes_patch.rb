module Acl::SafeAttributesPatch
  def self.included(base)
    base.send :include, InstanceMethods

    base.class_eval do
      alias_method_chain :safe_attribute?, :acl
      alias_method_chain :delete_unsafe_attributes, :acl
    end
  end

  module ClassMethods
    def self.included(base)
      base.class_eval do
        alias_method_chain :safe_attributes, :acl
      end
    end

    def safe_attributes_with_acl(*args)
      @unsafe_attributes ||= []
      if args.present?
        if args.last.is_a?(Hash) && args.last[:unsafe]
            args.pop
            @unsafe_attributes += args
        else
          safe_attributes_without_acl(*args)
        end
      else
        safe_attributes_without_acl(*args)
      end
    end
  end

  module InstanceMethods

    def safe_attribute_with_acl?(attr, user=nil)
      unsafe = self.class.instance_variable_get("@unsafe_attributes") || []
      unsafe += (self.class.superclass && self.class.superclass.instance_variable_get("@unsafe_attributes")) || []

      if unsafe.present?
        !unsafe.include?(attr)
      else
        safe_attribute_without_acl?(attr, user)
      end
    end

    def delete_unsafe_attributes_with_acl(attrs, user=User.current)
      unsafe = self.class.instance_variable_get("@unsafe_attributes") || []
      unsafe += (self.class.superclass && self.class.superclass.instance_variable_get("@unsafe_attributes")) || []

      if unsafe.present?
        attrs.dup.delete_if { |k,v| unsafe.include?(k.to_s) }
      else
        delete_unsafe_attributes_without_acl(attrs, user)
      end
    end
  end
end

unless Redmine::SafeAttributes.included_modules.include?(Acl::SafeAttributesPatch)
  Redmine::SafeAttributes.send(:include, Acl::SafeAttributesPatch)
end

unless Redmine::SafeAttributes::ClassMethods.included_modules.include?(Acl::SafeAttributesPatch::ClassMethods)
  Redmine::SafeAttributes::ClassMethods.send(:include, Acl::SafeAttributesPatch::ClassMethods)
end

