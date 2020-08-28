module Acl::Utils::Macros
  class IssueMacros < Acl::Utils::Macros::BaseMacros
    def target_class
      ::Issue
    end

    def fill_macros
      unless @static_loaded
        @static_loaded = true
        super

        macros_list.add('issue.id', '#', :fields, :id)

        (::Issue.column_names - %w(id lft rgt root_id lock_version parent_id)).each do |f|
          lbl = f.gsub(/\_id$/, '')
          if f.size != lbl.size
            ref = self.find_reflection_by_class(::Issue, f)
            if ref && ref.name.present?
              macros_list.add("issue.#{lbl}", f, :fields, ref.name.to_sym)
            else
              macros_list.add("issue.#{lbl}", f, :fields, lbl.to_sym)
            end

            macros_list.add("issue.#{lbl}.id", Proc.new { "#{::Issue.human_attribute_name(@value.to_s)} (ID)" }, :fields, f.to_sym)
          else
            macros_list.add("issue.#{f}", lbl, :fields, f.to_sym)
          end
        end


        %w(default_version_id name default_assigned_to_id inherit_members is_public description parent_id homepage identifier).each do |f|
          lbl = f.gsub(/\_id$/, '')
          if f.size != lbl.size
            ref = self.find_reflection_by_class(::Project, f)
            if ref && ref.name.present?
              macros_list.add("issue.project.#{lbl}", Proc.new { ::Project.human_attribute_name(@value.to_s) }, :project_fields, "project.#{ref.name}".to_sym)
            else
              macros_list.add("issue.project.#{lbl}", Proc.new { ::Project.human_attribute_name(@value.to_s) }, :project_fields, "project.#{lbl}".to_sym)
            end

            macros_list.add("issue.project.#{lbl}.id", Proc.new { "#{::Project.human_attribute_name(@value.to_s)} (ID)" }, :project_fields, "project.#{f}".to_sym)
          else
            macros_list.add("issue.project.#{f}", Proc.new { ::Project.human_attribute_name(@value.to_s) }, :project_fields, "project.#{f}".to_sym)
          end
        end
      end
      macros_list.add("issue.parent", :field_parent_issue, :fields, :parent)
      macros_list.add("issue.parent.id", Proc.new { "#{l(:field_parent_issue)} (ID)" }, :fields, :'parent.id')
      macros_list.add("issue.notes", :label_comment, :fields, :notes)

      IssueCustomField.order(:name).each do |cf|
        macros_list.add("issue.cf_#{cf.id}", cf.name, :custom_fields, Proc.new { |issue| format_object(cf.cast_value(issue.custom_field_value(cf)), false) })
      end

      ProjectCustomField.order(:name).each do |cf|
        macros_list.add("issue.project.cf_#{cf.id}", cf.name, :project_custom_fields, Proc.new { |issue| format_object(cf.cast_value(issue.project.custom_field_value(cf)), false) })
      end

      @loaded = false
    end
  end
end