module Acl
  module Helpers
    module ExtendHelper
      include ActionView::Helpers::NumberHelper

      def rmp_html_title(*args)
        if args.empty?
          title = @rmp_html_title || []
          title.reject(&:blank?).join(' - ')
        else
          @rmp_html_title ||= []
          @rmp_html_title += args
        end
      end

      def rmp_mailer_header(header=nil)
        if header.present?
          @rmp_mailer_header = "<div style=\"color:#000;font-weight:bold;font-family: 'Arial', serif; font-size: 17px;margin-bottom:5px;\">#{header}</div>".html_safe
        end
        (@rmp_mailer_header || '').html_safe
      end

      def calendar_for_time(field_id)
        if Acl::Settings['enable_periodpicker']
          javascript_tag("$(function() {
                  $('##{field_id}').periodpicker(datetimepickerOptions);
              });")
        end
      end

      def calendar_for_month(field_id)
        if Acl::Settings['enable_periodpicker']
          javascript_tag("$(function() {
                  $('##{field_id}').periodpicker(monthperiodpickerOptions)
              });")
        end
      end

      def options_for_button_css(css_class)
        css_classes = [''] # add predefined
        css_classes << css_class unless css_class.nil? || css_class == ''
        options = ''
        css_classes.sort.each do |css|
          css_name = css.split(/lb_btn_|acl_icon_/)
          css_name = (css_name.size == 2) ? css_name[1] : css_name[0]
          selected = (css == css_class) ? ' selected' : ''
          options << "<option value=\"#{css}\"#{selected}>#{css_name}</option>"
        end
        options.html_safe
      end

      def rmp_number_text(value, blank_default=nil, html=true)
        if value.is_a?(Integer) || value.is_a?(String)
          return value
        end
        if blank_default.nil?
          blank_default = (html ? '&times;'.html_safe : 'x')
        end
        unless blank_default
          blank_default = ''
        end

        value ? number_with_delimiter(number_with_precision(value, separator: '.', strip_insignificant_zeros: true, precision: 2), delimiter: ' ', separator: '.') : blank_default
      end

      def acl_tree(nested_set, torn=false)
        chain = []
        result = '<ul>'
        sz = nested_set.size
        nested_set.each_with_index do |node, ind|
          while chain.size > 0 && !node.is_descendant_of?(chain.last)
            result << '</ul></li>'
            chain.pop
          end

          leaf = node.leaf?
          if torn
            leaf ||= sz == (ind + 1)
            unless leaf
              nxt = nested_set[ind + 1]
              leaf ||= nxt.lft < node.lft || nxt.rgt > node.rgt
              if !leaf && node.respond_to?(:root_id)
                leaf ||= nxt.root_id != node.root_id
              end
            end
          end

          if leaf
            li_class = ''
          else
            li_class = ' acl-tree-parent'
          end

          if block_given?
            res = capture { yield(node, li_class) }
          else
            res = node.to_s
          end

          result << "<li id='acl-tree-node-#{node.id}' class='#{li_class}'>"
          result << res

          if leaf
            result << '</li>'
          else
            result << '<ul>'
            chain << node
          end
        end

        result << '</ul></li>' * chain.size
        result << '</ul>'
        result.html_safe
      end

      def acl_macros_list(macros_instance, field=nil)
        html = "<fieldset class='acl-macros-list closed'>"
        html << "<legend class='rm-icon'>#{l(:label_acl_macros_list)}</legend><div class='autoscroll'><table>"
        macros_instance.as_select.each do |(group, macros)|
          macros.each do |mc|
            html << "<tr class='acl-macros-item'><td>#{mc[0].html_safe}</td><td class='acl-macros-text'>#{mc[1]}</td></tr>"
          end
        end
        html << '</table></div>'
        html << '</fieldset>'
        html.html_safe
      end
    end
  end
end

ActionView::Base.send(:include, Acl::Helpers::ExtendHelper)

# require 'application_controller' unless defined?(ApplicationController)
unless ApplicationController.included_modules.include?(Acl::Helpers::ExtendHelper)
  ApplicationController.send(:include, Acl::Helpers::ExtendHelper)
end