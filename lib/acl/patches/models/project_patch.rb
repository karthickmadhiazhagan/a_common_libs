module Acl::Patches::Models
  module ProjectPatch
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :notified_users, :acl
      end
    end

    module ClassMethods
      def acl_base_allowed_condition(user, permission, options={})
        perm = Redmine::AccessControl.permission(permission)
        base_statement = (perm && perm.read? ? "#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}" : "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}")
        if !options[:skip_pre_condition] && perm && perm.project_module
          # If the permission belongs to a project module, make sure the module is enabled
          base_statement << " AND EXISTS (SELECT 1 AS one FROM #{EnabledModule.table_name} em WHERE em.project_id = #{Project.table_name}.id AND em.name='#{perm.project_module}')"
        end
        if project = options[:project]
          project_statement = project.project_condition(options[:with_subprojects])
          base_statement = "(#{project_statement}) AND (#{base_statement})"
        end
        "(#{base_statement})"
      end
    end

    module InstanceMethods
      def notified_users_with_acl
        @notified_users ||= User.active.joins(members: :project).where("#{Project.table_name}.id = ? and (#{Member.table_name}.mail_notification = ? or #{User.table_name}.mail_notification = 'all')", self.id, true)
      end
    end
  end
end