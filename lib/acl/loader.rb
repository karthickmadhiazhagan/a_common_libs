require_dependency 'acl'
require 'acl/hooks/view_hooks'
require 'acl/rails/action_view'
require 'acl/rails/session_store_bypass'
require 'acl/rails/rmp_sql_ext'
require 'acl/rails/rmp_reflection_ext'

require_dependency 'redmine/field_format'
require_dependency 'acl/redmine/field_format'
require_dependency 'acl/helpers/extend_helper'
require_dependency 'acl/issues_pdf_helper_patch'
require_dependency 'acl/url_helpers_patch'


require 'acl/patches'
Acl::Patches.load_all_dependencies

require_dependency 'acl/utils/macros/base_macros'
require_dependency 'acl/utils/macros/issue_macros'
require_dependency 'acl/utils/settings'