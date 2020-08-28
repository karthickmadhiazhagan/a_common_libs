module Acl::UrlHelpersPatch
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      alias_method_chain :uri_with_safe_scheme?, :acl
    end
  end

  module InstanceMethods
    def uri_with_safe_scheme_with_acl?(uri, schemes = ['http', 'https', 'ftp', 'mailto', nil])
      if uri.to_s.downcase.split(':').first == 'mailto'
        begin
          uri_with_safe_scheme_without_acl?(uri, schemes)
        rescue # just fix ruby bug
          true
        end
      else
        uri_with_safe_scheme_without_acl?(uri, schemes)
      end
    end
  end
end

unless Redmine::Helpers::URL.included_modules.include?(Acl::UrlHelpersPatch)
  Redmine::Helpers::URL.send :include, Acl::UrlHelpersPatch
end