module ActionView
  class LookupContext
    def rmp_get_all_files(name, prefixes = [], partial = false, keys = [], options = {}, outside_app=false)
      args = args_for_lookup(name, prefixes, partial, keys, options)
      @view_paths.rmp_get_all_files(args.shift, args.shift, args, outside_app)
    end
  end

  class PathSet
    def rmp_get_all_files(path, prefixes, args, outside_app)
      prefixes = [prefixes] if String === prefixes
      templates = []
      prefixes.each do |prefix|
        paths.each do |resolver|
          if outside_app
            templates += resolver.find_all_anywhere(path, prefix, *args)
          else
            templates += resolver.find_all(path, prefix, *args)
          end
        end
      end
      templates
    end
  end

  class Base
    # Render previous view in stack
    # For example: we need to patch view "issues/show.html.erb"
    # But only if our plugin enabled in project of issue
    # So, lets create file "issues/show.html.erb" in our plugin
    # In this file:
    # if @issue.project.module_enabled?(:plugin_name)
    #   render custom code
    # else
    #   <%= rmp_render_previous('issues/show', __FILE__) %>
    # end
    def rmp_render_previous(lookup_path, current_path, partial=false, locals={})
      all_files = self.lookup_context.rmp_get_all_files(lookup_path, [], partial, [], {}, false)
      return '' if all_files.blank?

      if current_path.blank?
        template = all_files.first
      else
        # current_path = current_path.to_s.gsub(Rails.root.to_s + '/', '')
        index = nil
        all_files.each_with_index do |t, ind|
          if t.identifier == current_path
            index = ind + 1
            break
          end
        end

        return '' if index.nil? || index >= all_files.size
        template = all_files[index]
      end
      return '' if template.blank?

      render file: template.identifier, locals: locals
    end
  end
end