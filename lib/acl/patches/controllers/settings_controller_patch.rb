module Acl::Patches::Controllers
  module SettingsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :plugin, :a_common_libs
      end
    end

    module InstanceMethods
      def plugin_with_a_common_libs
        if request.post?
          if params[:settings].nil? || params[:settings] == ''
            params[:settings] = HashWithIndifferentAccess.new
          end
        end
        plugin_without_a_common_libs
      end
    end
  end
end