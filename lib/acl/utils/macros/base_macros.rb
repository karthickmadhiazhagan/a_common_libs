module Acl
  module Utils
    module Macros
      class BaseMacros
        module MacrosHelper
          def find_reflection_by_class(klass, field)
            return nil unless klass.respond_to?(:reflections)
            klass.reflections.each_pair do |k, v|
              return v if v.foreign_key.to_s == field.to_s
            end

            nil
          end
        end

        include Singleton
        include MacrosHelper

        class MacrosCollection
          def all
            @macros_hash ||= {}
          end

          def [](name)
            self.all[name]
          end

          def add(name, label, group, value)
            self.add_item(item_class.new(name, label, group, value))
          end

          def add_item(*args)
            item = args.first
            if args.size == 4
              self.add(*args)
            elsif item.is_a?(Hash)
              self.add(item[:name], item[:label], item[:group], item[:value])
            else
              self.all[item.name] = item
            end
          end

          def delete(name)
            self.all.delete(name.to_s)
          end

          def grouped
            res = {}
            self.all.values.each do |item|
              res[item.group.to_s] ||= []
              res[item.group.to_s] << item
            end

            res
          end

          protected
          def item_class
            MacrosItem
          end
        end

        class MacrosItem
          include ::Rails.application.routes.url_helpers
          include ApplicationHelper
          include MacrosHelper

          attr_reader :name, :group

          def initialize(name, label=nil, group=nil, value=nil)
            @name = name
            @label = label
            @group = group
            @value = value
          end

          def suffix
            '{%'
          end

          def prefix
            '%}'
          end

          def macros_name
            "#{self.suffix}#{self.name}#{self.prefix}"
          end

          def label(object_klass=nil)
            if @label.is_a?(Symbol)
              l_or_humanize(@label)
            elsif @label.is_a?(String)
              if object_klass.present? && object_klass <= ActiveRecord::Base && object_klass.column_names.include?(@label)
                object_klass.human_attribute_name(@label)
              else
                @label
              end
            elsif @label.is_a?(Proc)
              c = self.instance_exec(&@label).to_s
              c = self.name.to_s.humanize if c.blank?
              c
            else
              self.name.to_s.humanize
            end
          end

          def replace(str, f_str, object, user=User.current, html=true, options={})
            vl = calc_value(object, user, html, options.merge(full_macros: f_str))
            if block_given?
              vl = yield(vl)
            end

            str.gsub(f_str, vl)
          end

          private

          def calc_value(object, user=User.current, html=true, options={})
            if @value.is_a?(Proc)
              v = self.instance_exec(object, user, html, options, &@value).to_s
            elsif @value.is_a?(Symbol)
              call_stack = @value.to_s.split('.')
              v = call_stack_methods(object, call_stack).to_s
            else
              v = @value.to_s
            end

            if html
              v.html_safe
            else
              v
            end
          end

          def call_stack_methods(object, method)
            return '' if object.blank?
            if method.is_a?(Array)
              obj = object
              method.each do |m|
                obj = call_stack_methods(obj, m)
              end
              object_value(obj)
            elsif object.respond_to?(method)
              object.send(method)
            elsif (ref = self.find_reflection_by_class(object.class, method)) && ref.present? && ref.name.present? && object.respond_to?(ref.name)
              object.send(ref.name)
            end
          end

          def object_value(object)
            if object.class <= ActiveRecord::Base && object.respond_to?(:name)
              object.name
            else
              format_object(object, false)
            end
          end

          def default_url_options
            options = { protocol: Setting.protocol}
            if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
              host, port, prefix = $2, $4, $5
              options.merge!({ host: host, port: port, script_name: prefix })
            else
              options[:host] = Setting.host_name
            end
            options
          end
        end


        MACROS_FINDER = /(
                      \{\%
                          (
                            ([\w\d\.\_]+)
                            (
                              \(
                                ([\w\d\,\s\_]*?)
                              \)
                            )?
                            (
                              \(\(
                                ([\s\S]*?)
                              \)\)
                            )?
                          )
                      \%\}
                     )/imx

        def as_select(user=User.current)
          res = macros_list.grouped
          I18n.with_locale((user.language.blank? ? Setting.default_language : user.language) || 'en') do
            res.each do |(k, v)|
              res[k] = v.map { |it| [it.label(self.target_class), it.macros_name] }.sort { |a, b| a <=> b }
            end
          end
          res
        end

        def replace(str, object, user=User.current, html=true, options={})
          return str if str.blank?
          res = str.clone

          I18n.with_locale((user.language.blank? ? Setting.default_language : user.language) || 'en') do
            self.detect_macros(str) do |macros, args, plain_text, full|
              if block_given?
                res = macros.replace(res, full, object, user, html, options.merge(args: args, text: plain_text)) do |value|
                  yield(macros, value, options)
                end
              else
                res = macros.replace(res, full, object, user, html, options.merge(args: args, text: plain_text))
              end
            end
          end

          res
        end

        def detect_macros(str)
          str.scan(MACROS_FINDER) do |m|
            full = m[0]
            macros_name = m[2]
            args = m[4]
            args = args.gsub(' ', '').split(',') if args.present?
            plain_text = m[6]

            if (m_item = macros_list[macros_name])
              yield(m_item, args, plain_text, full)
            end
          end
        end

        private

        def macros_list
          @macros_list ||= self.list_class.new

          unless @loaded
            @loaded = true
            fill_macros
          end

          @macros_list
        end

        protected

        def target_class
          raise NotImplemented
        end

        def list_class
          MacrosCollection
        end

        def fill_macros
          macros_list.add('pre', :label_acl_macro_pre, nil, Proc.new { |object, user, html, options| options[:text] })
          macros_list.add('now', :label_acl_macro_now, nil, Proc.new { format_time(Time.now) })
          macros_list.add('date_now', :label_acl_macro_date_now, nil, Proc.new { format_date(Date.today) })
          macros_list.add('current_user', :label_acl_macro_current_user, nil, Proc.new { User.current })
          macros_list.add('current_user.lastname', :label_acl_macro_current_user_lastname, nil, Proc.new { User.current.lastname })
          macros_list.add('current_user.firstname', :label_acl_macro_current_user_firstname, nil, Proc.new { User.current.firstname })
        end
      end
    end
  end
end