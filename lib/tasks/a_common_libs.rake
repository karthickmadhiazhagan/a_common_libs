namespace :redmine do
  namespace :acl do
    task move_generate_css: :environment do

      lb_icon_path = File.join(Rails.root, 'public', 'images', 'lb_uploaded_icons')
      acl_icon_path = File.join(Rails.root, 'public', 'images', 'acl_uploaded_icons')
      lb_css_path = File.join('plugins', 'luxury_buttons', 'assets', 'stylesheets', 'generated_icons.css')

      if File.directory?(lb_icon_path)
        if File.directory?(acl_icon_path)
          Dir[lb_icon_path + '/*'].each do |f|
            FileUtils.mv f, acl_icon_path
          end
          FileUtils.rm_rf(lb_icon_path)
        else
          FileUtils.mv lb_icon_path, File.join(Rails.root, 'public', 'images', 'acl_uploaded_icons')
        end
      end

      if File.exist?(lb_css_path)
        File.delete(lb_css_path)
      end

    end

    task clean_expired_caches: :environment do
      Rails.cache.cleanup
    end

    task clean_caches_by_regexp: :environment do
      env_regexp = ENV['REGEXP']
      unless env_regexp
        puts
        while true
          print 'Select RegExp: '
          STDOUT.flush
          env_regexp = STDIN.gets.chomp!
          break if env_regexp.present?
        end
        STDOUT.flush
        puts '===================================='
      end

      Rails.cache.delete_matched(Regexp.new(env_regexp), nil)
    end
  end
end