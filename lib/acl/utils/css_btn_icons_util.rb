module Acl::Utils
  class CssBtnIconsError < Exception; end

  class CssBtnIconsUtil
    include Redmine::I18n

    def self.options
      {
        icons_path: File.join(Rails.root, 'public', 'images', 'acl_uploaded_icons'),
        css_file: File.join('plugin_assets', 'a_common_libs', 'stylesheets', 'generated_icons.css'),
        max_width: 32,
        max_height: 32,
        max_size: 1073741824, # 1Mb
        available_ext: %w(png jpeg jpg gif jpe)
      }
    end

    attr_reader :temp_file, :filesize, :filename, :content_type

    def initialize(file)
      return if file.blank? || file.size <= 0
      begin
        @temp_file = file
        if file.respond_to?(:original_filename)
          @filename = file.original_filename
          @filename.force_encoding('UTF-8')
          @filename = escape_filename(@filename.mb_chars.downcase.to_s)
        end
        if file.respond_to?(:content_type)
          @content_type = file.content_type.to_s.chomp
        end
        if @content_type.blank? && @filename.present?
          @content_type = Redmine::MimeType.of(@filename)
        end

        if @content_type.blank? || Redmine::MimeType::MIME_TYPES[@content_type].blank? || (Redmine::MimeType::MIME_TYPES[@content_type].split(',') - self.class.options[:available_ext]).size > 0
          raise(CssBtnIconsError, l(:label_acl_upload_icons_unknown_file_type))
        end

        @filesize = file.size
        if @filesize == 0 || @filesize > self.class.options[:max_size]
          raise(CssBtnIconsError, l(:label_acl_upload_icons_max_filesize_exceed))
        end

        image = nil
        begin
          image = Magick::Image.from_blob(file.respond_to?(:read) ? file.read : file).first
        rescue Exception
          raise(CssBtnIconsError, l(:label_acl_upload_icons_unknown_file_type))
        end

        raise(CssBtnIconsError, l(:label_acl_upload_icons_unknown_file_type)) if image.nil?
        if image.columns > self.class.options[:max_width] && image.rows > self.class.options[:max_height]
          raise(CssBtnIconsError, l(:label_acl_upload_icons_resolution_exceed, resolution: "#{self.class.options[:max_width]}x#{self.class.options[:max_height]}"))
        end

        if File.exist?(File.join(self.class.options[:icons_path], self.filename))
          raise(CssBtnIconsError, l(:label_acl_upload_icons_file_exists, filename: self.filename))
        end

        begin
          save_to_disk
        rescue Exception
          raise(CssBtnIconsError, l(:label_acl_upload_icons_file_save_error, filename: self.filename))
        end
      ensure
        @temp_file = nil
      end
    end

    def self.generate_css_file
      files = Dir.glob(File.join(self.options[:icons_path], "*.{#{self.options[:available_ext].join(',')}}"))
      return if files.blank?

      css_file = File.join(Rails.root, 'public', self.options[:css_file])
      path = File.dirname(css_file)
      unless File.directory?(path)
        FileUtils.mkdir_p(path)
      end

      File.open(css_file, 'wt') do |f|
        files.each do |fl|
          clear_name = File.basename(fl, '.*')
          name = File.basename(fl)
          folder = File.basename(self.options[:icons_path])

          f.write(".acl_icon_#{clear_name} { background-image: url(../../../images/#{folder}/#{name}); }\n")
        end
      end
    end

    def self.include_generated_css
      return nil unless File.exists?(File.join(Rails.root, 'public', self.options[:css_file]))

      css_file_path = self.options[:css_file]
      css_file_path = '/' + css_file_path unless css_file_path.start_with?('/')

      css_file_path = Redmine::Utils.relative_url_root + css_file_path unless css_file_path.starts_with?("#{Redmine::Utils.relative_url_root}")

      "<link id='acl-generated-icons' href='#{css_file_path}' media='screen' rel='stylesheet' type='text/css'>".html_safe
    end

    private

    def escape_filename(value)
      just_filename = value.gsub(/\A.*(\\|\/)/m, '')
      just_filename.gsub(/[\/\?\%\*\:\|\"\'<>\n\r]+/, '_')
    end

    def save_to_disk
      return unless self.temp_file
      Rails.logger.info("Saving acl icon '#{self.filename}' (#{self.filesize} bytes)") if Rails.logger
      unless File.directory?(self.class.options[:icons_path])
        FileUtils.mkdir_p(self.class.options[:icons_path])
      end
      diskfile = File.join(self.class.options[:icons_path], self.filename)
      File.open(diskfile, 'wb') do |f|
        if self.temp_file.respond_to?(:read)
          self.temp_file.rewind
          while (buffer = self.temp_file.read(8192))
            f.write(buffer)
          end
        else
          f.write(self.temp_file)
        end
      end
    end
  end
end