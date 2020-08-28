module Acl::Patches::Models
  module MailerPatch
    def self.included(base)
      base.send :include, AbstractController::Callbacks
      base.send :include, InstanceMethods

      base.class_eval do
        before_action :default_mailer_attachment
      end
    end

    module InstanceMethods
      def default_mailer_attachment
        begin
          if self.send('_layout', ['html']) == "rmp_mailer"
            custom_logo_path = File.join(Rails.root, 'files', 'logo', 'logo.png')
            if File.exist?(custom_logo_path)
              logo = File.read(custom_logo_path)
              @custom_logo = true
            else
              logo = File.read(File.join(Rails.root, 'plugins', 'a_common_libs', 'assets', 'images', 'logo.png'))
            end
            attachments.inline['logo.png'] = logo
          end
        rescue Exception => e
          Rails.logger.error "Email logo attachment error: #{e.message}" if Rails.logger
        end
      end
    end
  end
end