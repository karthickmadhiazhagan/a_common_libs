module Acl
end

begin
  Acl::Utils::CssBtnIconsUtil.generate_css_file
rescue Exception => ex
  Rails.logger.info "WARNING: Cannot generate custom css for button icons #{ex.message}" if Rails.logger
end