module Acl::Patches::Helpers
  module ApplicationHelperPatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, Acl::Helpers::ExtendHelper

      base.class_eval do
        alias_method_chain :calendar_for, :acl
      end
    end

    module InstanceMethods
      def calendar_for_with_acl(field_id, period = false)
        if Acl::Settings['enable_periodpicker']
          include_calendar_headers_tags
          javascript_tag("$(function() {
              $('##{field_id}').periodpicker(#{period ? '$.extend(periodpickerOptionsRange, {end:\'#' + period + '\'})' : 'periodpickerOptions'});$('##{field_id}').show().css({'position': 'absolute', 'width': '1px', 'height': '1px', 'margin-left': '20px', 'margin-top': '10px'});
          });")
        else
          calendar_for_without_acl(field_id)
        end
      end
    end
  end
end
