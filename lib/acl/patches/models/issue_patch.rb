module Acl::Patches::Models
  module IssuePatch
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend(ClassMethods)

      base.class_eval do
        attr_accessor :acl_cf_casted_values
        class << self
          alias_method_chain :visible_condition, :acl
          alias_method_chain :allowed_target_projects, :acl
        end

        alias_method_chain :safe_attributes=, :acl

        safe_attributes 'custom_field_values_append',
                        'custom_field_values_delete',
                        if: lambda { |issue, user| issue.new_record? || issue.attributes_editable?(user) }
      end
    end

    module ClassMethods
      def allowed_target_projects_with_acl(user=User.current, current_project=nil)
        sc = allowed_target_projects_without_acl(user, current_project)
        fp = user.favourite_project
        if fp.present?
          sc.order(Arel.sql("case when #{Project.table_name}.id = #{fp.id} then 0 else 1 end"))
        else
          sc
        end
      end

      def acl_load_custom_values(issues, custom_fields)
        issue_ids = issues.map(&:id)
        custom_values_scope = acl_custom_values_scope(issue_ids, custom_fields)
        return if custom_values_scope.nil?

        cfs = IssueCustomField.joins("INNER JOIN custom_fields_trackers cft on cft.custom_field_id = #{CustomField.table_name}.id
                                      LEFT JOIN custom_fields_projects cfp on cfp.custom_field_id = #{CustomField.table_name}.id
                                      INNER JOIN (
                                          SELECT i.project_id, i.tracker_id
                                          FROM #{Issue.table_name} i
                                          WHERE i.id IN (#{(issue_ids + [0]).join(',')})
                                          GROUP BY i.project_id, i.tracker_id
                                      ) i ON i.tracker_id = cft.tracker_id and (i.project_id = cfp.project_id OR #{CustomField.table_name}.is_for_all = #{Issue.connection.quoted_true})
                                     ")
                              .select("#{CustomField.table_name}.*, i.tracker_id, i.project_id")
                              .distinct
                              .inject({}) { |h, it|
          h["#{it.project_id}-#{it.tracker_id}"] ||= {}
          h["#{it.project_id}-#{it.tracker_id}"][it.id] = it
          h
        }

        format_hash = {}
        cvs = custom_values_scope.inject({}) { |h, it|
          h[it.customized_id] ||= {}
          h[it.customized_id][it.custom_field_id] ||= []
          h[it.customized_id][it.custom_field_id] << it

          if it.custom_field.format.try(:class) <= Redmine::FieldFormat::RecordList
            format_hash[it.custom_field.format] ||= []
            format_hash[it.custom_field.format] << it
          end

          h
        }

        format_hash.keys.each do |key|
          format_hash[key] = key.cast_value_records(format_hash[key].first.custom_field, format_hash[key].map(&:value)).inject({}) { |h, it| h[it.id.to_s] = it; h }
        end

        issues.each do |issue|
          issue.acl_cf_casted_values = {}
          issue.acl_available_custom_fields = cfs["#{issue.project_id}-#{issue.tracker_id}"]
          cv = cvs[issue.id]
          custom_fields.each do |cf|
            cfv = issue.custom_field_value_by_id(cf.id)
            next if cfv.blank?
            if cv.present? && cv[cf.id].present?
              values = cv[cf.id]
              cfv.acl_trimmed_size = values.first.attributes['cnt'].to_i
            else
              values = []
            end
            if cf.format.try(:class) <= Redmine::FieldFormat::RecordList && (format_hash.has_key?(cf.format) || values.blank?)
              cf.acl_cf_casted_values ||= {}
              if values.present?
                hashed_values = values.inject({}) do |h, v|
                  h[v.value.to_s] = format_hash[cf.format][v.value.to_s]
                  cf.acl_cf_casted_values[v.value.to_s] = h[v.value.to_s]
                  h
                end
              else
                hashed_values = { 0 => nil }
              end

              issue.acl_cf_casted_values[cf.id] = hashed_values
            end
            cfv.send :value=, values, '=', true
          end
        end
      end

      def acl_custom_values_scope(issue_ids, custom_fields)
        case Issue.connection.adapter_name.downcase.to_sym
          when :mysql, :mysql2
            acl_custom_values_scope_mysql(issue_ids, custom_fields.map(&:id)).preload(:custom_field)
          when :postgresql, :sqlserver
            acl_custom_values_scope_postgre(issue_ids, custom_fields.map(&:id)).preload(:custom_field)
          else
            nil
        end
      end

      def acl_custom_values_scope_mysql(issue_ids, custom_field_ids)
        CustomValue.joins("INNER JOIN
                          (
                            SELECT cv.id,
                                   cv.cnt
                            FROM
                            (
                              SELECT cv.id,
                                     cv_m.cnt,
                                     @row_num := if (@previous = CONCAT(i.id, '_', cf.id) and cf.multiple = #{Issue.connection.quoted_true} and cf.acl_trim_multiple = #{Issue.connection.quoted_true}, @row_num + 1, 1) as row_num,
                                     @previous := CONCAT(i.id, '_', cf.id)
                              FROM custom_values cv
                                   INNER JOIN issues i on i.id = cv.customized_id
                                   INNER JOIN custom_fields cf on cf.id = cv.custom_field_id
                                   INNER JOIN (SELECT COUNT(1) as cnt, cv.custom_field_id, cv.customized_id FROM custom_values cv WHERE cv.customized_type = 'Issue' and cv.custom_field_id IN (#{(custom_field_ids + [0]).join(',')}) and cv.customized_id IN (#{(issue_ids + [0]).join(',')}) GROUP BY cv.custom_field_id, cv.customized_id) cv_m on cv_m.custom_field_id = cf.id and cv_m.customized_id = i.id
                                   CROSS JOIN (select @row_num := 0, @previous := null) tmp_vars
                              WHERE cv.customized_type = 'Issue'
                                and cv.custom_field_id IN (#{(custom_field_ids + [0]).join(',')})
                                and i.id IN (#{(issue_ids + [0]).join(',')})
                              ORDER BY i.id, cv.custom_field_id, cv.id
                            ) cv
                            WHERE cv.row_num <= 3
                          ) cv on cv.id = #{CustomValue.table_name}.id
                          ")
            .order(:customized_id, :custom_field_id, :id)
            .select("#{CustomValue.table_name}.*, cv.cnt")
      end

      def acl_custom_values_scope_postgre(issue_ids, custom_field_ids)
        CustomValue.joins("INNER JOIN
                          (
                            SELECT cv.id,
                                   cv.cnt
                            FROM
                            (
                              SELECT cv.id,
                                     cv_m.cnt,
                                     case when cf.multiple = #{Issue.connection.quoted_true} and cf.acl_trim_multiple = #{Issue.connection.quoted_true} then 1 else 0 end as mlt,
                                     ROW_NUMBER() OVER (PARTITION BY i.id, cv.custom_field_id ORDER BY i.id, cv.custom_field_id, cv.id) as row_num
                              FROM issues i
                                   INNER JOIN custom_values cv on cv.customized_id = i.id
                                   INNER JOIN custom_fields cf on cf.id = cv.custom_field_id
                                   INNER JOIN (SELECT COUNT(1) as cnt, cv.custom_field_id, cv.customized_id FROM custom_values cv WHERE cv.customized_type = 'Issue' and cv.custom_field_id IN (#{custom_field_ids.join(',')}) and cv.customized_id IN (#{issue_ids.join(',')}) GROUP BY cv.custom_field_id, cv.customized_id) cv_m on cv_m.custom_field_id = cf.id and cv_m.customized_id = i.id
                              WHERE cv.customized_type = 'Issue'
                                and cv.custom_field_id IN (#{custom_field_ids.join(',')})
                                and i.id IN (#{issue_ids.join(',')})
                            ) cv
                            WHERE cv.mlt = 0 OR cv.row_num <= 3
                          ) cv on cv.id = #{CustomValue.table_name}.id
                          ")
            .order(:customized_id, :custom_field_id, :id)
            .select("#{CustomValue.table_name}.*, cv.cnt")
      end

      def visible_condition_with_acl(user, options={})
        original = "(#{visible_condition_without_acl(user, options)})"
        extended = acl_extend_issue_visibility(user, options)
        limit = acl_limit_issue_visibility(user, options)
        if extended.present?
          base_statement = Project.acl_base_allowed_condition(user, :view_issues, options)
          original = "(#{original} OR (#{base_statement} AND (#{extended})))"
        end
        if limit.present?
          original = "(#{original} AND (#{limit}))"
        end
        original
      end
      def acl_extend_issue_visibility(user, options={})
        nil
      end
      def acl_limit_issue_visibility(user, options={})
        nil
      end
    end

    module InstanceMethods
      def safe_attributes_with_acl=(attrs, user=User.current)
        if attrs.present?
          editable_custom_field_ids = editable_custom_field_values(user).map {|v| v.custom_field_id.to_s}
          if attrs['custom_field_values_append'].present?
            attrs['custom_field_values_append'].select! { |k, v| editable_custom_field_ids.include?(k.to_s) }
          end

          if attrs['custom_field_values_delete'].present?
            attrs['custom_field_values_delete'].select! { |k, v| editable_custom_field_ids.include?(k.to_s) }
          end

          if (attrs.keys.map(&:to_s) - %w(custom_field_values_append custom_field_values_delete lock_version notes private_notes)).size == 0
            attrs.delete('lock_version')
          end
        end

        send :safe_attributes_without_acl=, attrs, user
      end
    end
  end
end