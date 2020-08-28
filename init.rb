Redmine::Plugin.register :a_common_libs do
  name 'A common libraries'
  author 'Danil Kukhlevskiy'
  description 'This is a plugin for including common libraries'
  version '2.5.7'
  url 'http://rmplus.pro/'
  author_url 'http://rmplus.pro/'

  settings partial: 'settings/a_common_libs',
           default: { },
           auto: {}

  menu :custom_menu, :us_favourite_proj_name, nil, caption: Proc.new{ ('<div class="title">' + User.current.favourite_project.name + '</div>').html_safe }, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) }
  menu :custom_menu, :us_favourite_proj_link, nil, caption: Proc.new{ ('<a href="' + Redmine::Utils.relative_url_root + '/projects/'+User.current.favourite_project.identifier+'" class="no_line"><span>' + User.current.favourite_project.name + '</span></a>').html_safe }, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) }
  menu :custom_menu, :us_favourite_proj_issues, nil, caption: Proc.new{ ('<a href="' + Redmine::Utils.relative_url_root + '/projects/'+User.current.favourite_project.identifier+'/issues" class="no_line"><span>' + I18n.t(:label_issue_plural) + '</span></a>').html_safe }, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) }
  menu :custom_menu, :us_favourite_proj_new_issue, nil, caption: Proc.new{ ('<a href="' + Redmine::Utils.relative_url_root + '/projects/'+User.current.favourite_project.identifier+'/issues/new" class="no_line"><span>' + I18n.t(:label_issue_new) + '</span></a>').html_safe}, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) }
  menu :custom_menu, :us_favourite_proj_wiki, nil, caption: Proc.new{ ('<a href="' + Redmine::Utils.relative_url_root + '/projects/'+User.current.favourite_project.identifier+'/wiki" class="no_line"><span>' + I18n.t(:label_wiki) + '</span></a>').html_safe }, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) && User.current.favourite_project.module_enabled?(:wiki) }
  menu :custom_menu, :us_new_issue, nil, caption: Proc.new{ ('<a href="' + Redmine::Utils.relative_url_root + '/projects/'+User.current.favourite_project.identifier+'/issues/new" class="no_line"><span>' + I18n.t(:us_of_issue) + '</span></a>').html_safe }, if: Proc.new { User.current.logged? && User.current.favourite_project.is_a?(Project) }
  menu :custom_menu, :api_log_for_plugins, {controller: 'api_log_for_plugins', action: 'index'}, caption: Proc.new{ ApiLogForPlugin.build_link_unread_log }, if: Proc.new { User.current.logged? && User.current.try(:admin) }, html: {class: 'no_line'}
  menu :custom_menu, :acl_update_counters, '#', caption: Proc.new { ('<span>'+I18n.t(:label_acl_refresh_ajax_counters)+'</span>').html_safe }, if: Proc.new { User.current.logged? }, html: {class: 'in_link ac_refresh', id: 'refresh_ajax_counters'}

  requires_redmine '4.0.0'

  require 'acl/alias_patch'
  Module.send(:include, AliasPatch)
  require 'acl/safe_attributes_patch'
  require 'acl/rails/serialized'

  p = Redmine::AccessControl.permission(:view_issues)
  if p && p.project_module == :issue_tracking
    p.actions << 'issues/acl_edit_form'
  end

  Redmine::WikiFormatting::Macros.register do
    macro :acl_html do |obj, args, text|
      sanitize(text, tags: %w(strong del i b a ul li h1 h2 h3 p big small span div), attributes: %w(href class title style))
    end
  end
end

require 'acl/i18n_backend_pluralization'
unless Redmine::I18n::Backend::Implementation.included_modules.include?(Acl::I18nImplementationPatch)
  Redmine::I18n::Backend::Implementation.send :include, Acl::I18nImplementationPatch
end
unless Redmine::I18n.included_modules.include?(Acl::I18nPatch)
  Redmine::I18n.send(:include, Acl::I18nPatch)
end

Rails.application.config.session_store :active_record_store
require 'acl/acts_as_customizable_patch'
Rails.application.config.to_prepare do
  load 'acl/loader.rb'
  load 'acl/safe_attributes_patch.rb'
  load 'acl/rails/serialized.rb'
end

Rails.application.config.after_initialize do
  if Redmine::Plugin.installed?(:ajax_counters)
    raise Redmine::PluginRequirementError.new("'Ajax Counter' now moved to 'A Common Libs' plugin. You must delete ajax_counter from your server.")
  end

  end_of_prepare_block = Proc.new do
    unless IssueQuery.included_modules.include?(Acl::IssueQueryPatch)
      IssueQuery.send(:include, Acl::IssueQueryPatch)
    end

    unless ApplicationHelper.included_modules.include?(Acl::ApplicationHelperPatch)
      ApplicationHelper.send(:include, Acl::ApplicationHelperPatch)
    end

    require 'acl/redmine/query_custom_field_association_column'
  end

  # run now and Add to end of to_prepare block chain
  end_of_prepare_block.call
  ActiveSupport::Reloader.to_prepare({}, &end_of_prepare_block)
end