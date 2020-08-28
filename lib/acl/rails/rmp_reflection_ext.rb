module ActiveRecord
  # Condition over ON for joins\preload\eager_load
  #
  # Naming: conditions_over_on_{foreign_table_name}_{foreign_table_key}_{result_table_name}_{result_table_key}
  # class SampleTableA < ActiveRecord::Base
  #   # id - integer
  #   has_many sample_table_a, foreign_key: :value
  #
  # end
  # class SampleTableB < ActiveRecord::Base
  #   # id - integer
  #   # value - string
  #   belongs_to :sample_table_a, foreign_key: :value
  #
  #   def self.conditions_over_on_sample_table_b_value_sample_table_a_id
  #     Proc.new { |o, alias_name| "CAST(case when #{alias_name} = '' then '0' else #{alias_name} end AS decimal(30, 0))" }
  #   end
  # end

  module Reflection
    class AbstractReflection
      if Rails.version < '5.2.4'
        Rails.logger.info 'Loaded rmp_reflection_ext version 5.2.3'

        def build_join_constraint_with_rmp(table, foreign_table)

          if foreign_table.present? && table.present?
            key         = join_keys.key
            foreign_key = join_keys.foreign_key
            bclass = table.name.classify.safe_constantize
            foreign_bclass = foreign_table.name.classify.safe_constantize

            if bclass && foreign_bclass
              proc_name = "conditions_over_on_#{table.name}_#{key}_#{foreign_table.name}_#{foreign_key}"

              if bclass.respond_to?(proc_name)
                table = table.clone
                table.condition_over = bclass.send(proc_name)
              end

              proc_name = "conditions_over_on_#{foreign_table.name}_#{foreign_key}_#{table.name}_#{key}"

              if foreign_bclass.respond_to?(proc_name)
                foreign_table = foreign_table.clone
                foreign_table.condition_over = foreign_bclass.send(proc_name)
              end
            end
          end

          build_join_constraint_without_rmp(table, foreign_table)
        end

        alias_method_chain :build_join_constraint, :rmp
      else
        Rails.logger.info 'Loaded rmp_reflection_ext version 5.2.4'

        def join_scope_with_rmp(table, foreign_table, foreign_klass)
          if foreign_table.present? && table.present?
            key         = join_keys.key
            foreign_key = join_keys.foreign_key
            bclass = table.name.classify.safe_constantize

            if bclass && foreign_klass
              proc_name = "conditions_over_on_#{table.name}_#{key}_#{foreign_table.name}_#{foreign_key}"

              if bclass.respond_to?(proc_name)
                table = table.clone
                table.condition_over = bclass.send(proc_name)
              end

              proc_name = "conditions_over_on_#{foreign_table.name}_#{foreign_key}_#{table.name}_#{key}"

              if foreign_klass.respond_to?(proc_name)
                foreign_table = foreign_table.clone
                foreign_table.condition_over = foreign_klass.send(proc_name)
              end
            end
          end

          join_scope_without_rmp(table, foreign_table, foreign_klass)
        end

        alias_method_chain :join_scope, :rmp
      end
    end
  end
end