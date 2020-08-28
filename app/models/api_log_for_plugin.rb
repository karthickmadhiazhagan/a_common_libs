class ApiLogForPlugin < ActiveRecord::Base
  belongs_to :user

  def self.build_link_unread_log()
    link = "<span>#{l(:api_log_for_plugins_errors)}</span>"
    link << User.current.acl_ajax_counter('acl_not_served_log_count', {period: 0, css: 'unread'})
    link.html_safe
  end

end