module Acl
  module ApplicationHelperPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :link_to_user, :acl
      end
    end

    module InstanceMethods
      def link_to_user_with_acl(user, options={})
        key = [user.class.name, user.try(:id), options.deep_dup]
        @_link_to_user_acl_cache ||= {}
        @_link_to_user_acl_cache[key] ||= link_to_user_without_acl(user, options)
      end
    end
  end
end