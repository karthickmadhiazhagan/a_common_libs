module Acl
  module I18nPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :l, :acl
      end
    end

    module InstanceMethods
      def l_with_acl(*args)
        if args.size == 1 && args.first.is_a?(Hash) && args.first[:default].present?
          return args.first[:default]
        end

        l_without_acl(*args)
      end
    end
  end
end