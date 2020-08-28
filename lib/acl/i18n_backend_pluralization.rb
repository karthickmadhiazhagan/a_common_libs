module Acl
  module I18nImplementationPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :store_translations, :acl
      end
    end

    module InstanceMethods
      def store_translations_with_acl(locale, data, options = {})
        tr = store_translations_without_acl(locale, data, options = {})
        if locale.to_s == 'ru'
          tr.deep_merge!(
              { i18n:
                    { plural:
                          { rule: lambda { |n|
                            if n % 10 == 1 && n % 100 != 11
                              :one
                            elsif (2..4).include?(n % 10) && !(12..14).include?(n % 100)
                              :few
                            elsif n % 10 == 0 || (5..9).include?(n % 10) || (11..14).include?(n % 100)
                              :many
                            else
                              :other
                            end
                          }
                          }
                    }
              }
          )
        end
        tr
      end
    end
  end
end