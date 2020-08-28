module Acl::Hooks
  class ViewHooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_top, partial: 'hooks/a_common_libs/view_issues_form_details_top'
    render_on :view_layouts_base_html_head, partial: 'hooks/a_common_libs/html_head'
    render_on :view_layouts_base_body_top, partial: 'hooks/a_common_libs/view_layouts_base_body_top'
    render_on :view_my_account, partial: 'hooks/a_common_libs/favourite_project'
    render_on :view_users_form, partial: 'hooks/a_common_libs/favourite_project'
    render_on :view_custom_fields_form_upper_box, partial: 'hooks/a_common_libs/view_custom_fields_form_upper_box'
  end
end
