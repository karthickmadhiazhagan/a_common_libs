class AclStyleCssController < ApplicationController
  def upload_icons
    if request.post?
      begin
        Acl::Utils::CssBtnIconsUtil.new(params[:css_icon])
        Acl::Utils::CssBtnIconsUtil.generate_css_file
      rescue Exception => ex
        render plain: ex.message, status: 500
        return
      end

      render plain: Acl::Utils::CssBtnIconsUtil.include_generated_css
      return
    end
    render layout: false
  end
end