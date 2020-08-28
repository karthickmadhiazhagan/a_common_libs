module Acl
  class Settings
    include Singleton

    class << self
      def method_missing(key, *args)
        if self.public_method_defined?(key)
          self.instance.send(key, *args)
        else
          super
        end
      end
    end

    def [](key)
      key = key.to_s
      if Setting.plugin_a_common_libs[key].present?
        return !%w(false 0).include?(Setting.plugin_a_common_libs[key].to_s)
      end
      settings[key].present?
    end

    def append_setting(key, plugin)
      key = key.to_s
      plugin = plugin.to_s.to_sym
      settings[key] ||= []
      return if settings[key].present? && settings[key].include?(plugin)
      settings[key] << plugin
    end

    def used_by(key)
      settings[key] || []
    end

    private

    def settings
      @settings ||= {}
    end
  end
end