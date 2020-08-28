module Acl::Patches::Controllers
  module IssuesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :show, :acl
        skip_before_action :authorize, only: [:acl_cf_trimmed_all, :acl_edit_form]
      end
    end

    module InstanceMethods
      def show_with_acl
        prepend_view_path File.join(Redmine::Plugin.find(:a_common_libs).directory, 'app', 'views', 'acl_prepended_views')
        show_without_acl
      end

      def acl_edit_form
        return unless find_issue
        return unless authorize
        @heads_for_wiki_formatter_included = params[:wiki_js].to_i == 1
        @extentions_for_wiki_formatter_included = @heads_for_wiki_formatter_included
        @calendar_headers_tags_included = params[:calendar_js].to_i == 1
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
        @priorities = IssuePriority.active
        @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
        @relation = IssueRelation.new
        retrieve_previous_and_next_issue_ids
        render layout: 'acl_ajax_edit_issue_layout'
      end

      def acl_cf_trimmed_all
        return if find_issue == false
        unless @issue.visible?
          render_403
          return
        end
        @cf = @issue.visible_custom_field_values.find { |cf| cf.custom_field_id == params[:cf_id].to_i }
        if @cf.blank?
          render_404
          return
        end

        render layout: false
      end
    end
  end
end