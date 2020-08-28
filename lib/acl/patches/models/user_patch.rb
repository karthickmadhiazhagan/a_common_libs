module Acl::Patches::Models
  module UserPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        attr_writer :api_request

        alias_method_chain :allowed_to?, :acl
      end
    end

    module InstanceMethods
      def favourite_project
        @fv_pr ||= (Project.where(id: self.preference.try(:favourite_project_id).to_i).first || get_favourite_project)
      end

      def get_favourite_project
        return @fav_project if @fav_project
        @fav_project = Project.select("#{Project.table_name}.*, COUNT(#{Journal.table_name}.id) AS num_actions")
                              .joins({ issues: :journals })
                              .where("#{Journal.table_name}.user_id = ?", id)
                              .group("projects.#{Project.column_names.join(', projects.')}")
                              .order('num_actions DESC')
                              .limit(1)
                              .try(:first)

        @fav_project = Project.all.first unless @fav_project

        if self.preference.try(:favourite_project_id).nil? && !@fav_project.nil?
          self.preference = self.build_preference if self.preference.blank?
          self.preference.favourite_project_id = @fav_project.id
          self.preference.save
        end

        @fav_project
      end

      def acl_user_to_server_time(time, ignore_zone=false)
        return nil if time.blank?
        zone = self.time_zone

        if time.is_a?(Time) && ignore_zone
          time = time.strftime('%Y-%m-%d %H:%M:%S')
        end

        if time.is_a?(String)
          if zone.blank?
            if self.class.default_timezone == :utc
              tm = ActiveSupport::TimeZone[Time.now.utc.zone].parse(time)
            else
              tm = Time.parse(time)
            end
          else
            tm = zone.parse(time)
          end
        else
          tm = time
        end

        if tm
          if self.class.default_timezone == :utc
            tm = tm.utc
          elsif self.class.default_timezone == :local
            tm = tm.localtime
          end
        end

        tm
      end

      def acl_server_to_user_time(time)
        return nil unless time
        if time.is_a?(String)
          if self.class.default_timezone == :utc
            time = time.strip + ' UTC'
          end
          tm = Time.parse(time) rescue nil
          return nil unless tm
        else
          tm = time
        end
        zone = self.time_zone
        zone ? tm.in_time_zone(zone) : tm
      end

      def acl_not_served_log_count(view_context=nil, params=nil, session=nil)
        ApiLogForPlugin.where(served: false).size
      end

      def acl_ajax_counter(action_name, options={})
        options ||= {}
        options[:css] = options[:css] ? 'ac_counter ' + options[:css].to_s : 'ac_counter'
        if Acl::Settings['enable_ajax_counters']
          options[:period] = options[:period] ? options[:period].to_i : 180
          params = []
          if options[:params].present? && options[:params].is_a?(Hash)
            options[:params].each do |(k, v)|
              params << "#{k}=#{v}" if k.present? && v.present?
            end
          end
          action_md5 = action_name
          if params.present?
            action_md5 += '?' + params.join('&')
          end

          action_md5 = Digest::MD5.hexdigest(action_md5)

          old_counter = AclAjaxCounter[action_md5]
          new_counter = { action_name: action_name, period: options[:period].to_i, params: options[:params] }
          if old_counter.blank? || old_counter != new_counter
            AclAjaxCounter[action_md5] = new_counter
          end

          "<span data-id='#{action_md5}' class='#{options[:css]}'></span>".html_safe
        elsif options.present? && options[:sync_count].present?
          if options[:sync_count].is_a?(Proc)
            count = self.instance_exec(&options[:sync_count]).to_i
          else
            count = options[:sync_count].to_i
          end
          if count > 0
            "<span class='#{options[:css]}'>#{count}</span>".html_safe
          else
            ''
          end
        else
          ''
        end
      end

      def api_request?
        @api_request
      end

      def now
        if self.time_zone.present?
          Time.now
        else
          Time.now.in_time_zone(self.time_zone)
        end
      end

      def allowed_to_with_acl?(action, context, options={}, &block)
        if block_given? || context.is_a?(Array)
          if block_given?
            allowed_to_without_acl?(action, context, options) do |role, user|
              yield(role, user)
            end
          else
            allowed_to_without_acl?(action, context, options)
          end
        else
          @_allowed_to ||= {}
          key = [action, context, options[:global]]

          return !!@_allowed_to[key] if @_allowed_to.has_key?(key)
          @_allowed_to[key] = allowed_to_without_acl?(action, context, options)
        end
      end
    end

  end
end
