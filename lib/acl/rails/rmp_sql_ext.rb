module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        args * ' + '
      end

      def rmp_char_length(column)
        "CHAR_LENGTH(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "SUBSTRING(#{column}, #{start_index}, #{length})"
      end

      def rmp_current_time
        "CURDATE()"
      end

      def rmp_days_diff(start_date, end_date)
        "EXTRACT(DAY FROM #{end_date} - #{start_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "EXTRACT(SECOND FROM #{end_date} - #{start_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end


      def rmp_get_date(field)
        "DATE(#{field})"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_date_iso(field)
        "DATE_FORMAT(#{field}, '%Y-%m-%d')"
      end

      def rmp_add_month(field, num)
        "DATE_ADD(#{field}, INTERVAL #{num} MONTH)"
      end

      def rmp_add_days(field, days)
        "DATE_ADD(#{field}, INTERVAL #{days} DAY)"
      end

      def rmp_add_seconds(field, secs)
        "DATE_ADD(#{field}, INTERVAL #{secs} SECOND)"
      end
    end

    class AbstractMysqlAdapter < AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        "CONCAT(#{args * ', '})"
      end

      def rmp_char_length(column)
        "CHAR_LENGTH(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "SUBSTRING(#{column}, #{start_index + 1}, #{length})"
      end

      def rmp_current_time
        'CURDATE()'
      end

      def rmp_days_diff(start_date, end_date)
        "TIMESTAMPDIFF(DAY, #{start_date}, #{end_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "TIMESTAMPDIFF(SECOND, #{start_date}, #{end_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end

      def rmp_get_date(field)
        "DATE(#{field})"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_date_iso(field)
        "DATE_FORMAT(#{field}, '%Y-%m-%d')"
      end

      def rmp_add_month(field, num)
        "DATE_ADD(#{field}, INTERVAL #{num} MONTH)"
      end

      def rmp_add_days(field, days)
        "DATE_ADD(#{field}, INTERVAL #{days} DAY)"
      end

      def rmp_add_seconds(field, secs)
        "DATE_ADD(#{field}, INTERVAL #{secs} SECOND)"
      end
    end

    class SQLServerAdapter < AbstractAdapter
      def rmp_random
        'RAND()'
      end

      def rmp_concat(*args)
        args * ' + '
      end

      def rmp_char_length(column)
        "LEN(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "SUBSTRING(#{column}, #{start_index}, #{length})"
      end

      def rmp_current_time
        'NOW()'
      end

      def rmp_days_diff(start_date, end_date)
        "DATEDIFF(day, #{start_date}, #{end_date})"
      end

      def rmp_seconds_diff(start_date, end_date)
        "DATEDIFF(second, #{start_date}, #{end_date})"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as DECIMAL)"
      end

      def rmp_get_date(field)
        "CAST(#{field} AS DATE)"
      end

      def rmp_date_iso(field)
        "CONVERT(nvarchar, #{field}, 23)"
      end

      def rmp_get_datetime(field)
        field
      end

      def rmp_add_month(field, num)
        "DATEADD(month, #{num}, #{field})"
      end

      def rmp_add_days(field, days)
        "DATEADD(day, #{days}, #{field})"
      end

      def rmp_add_seconds(field, secs)
        "DATEADD(second, #{secs}, #{field})"
      end
    end

    class PostgreSQLAdapter < AbstractAdapter
      def rmp_random
        'random()'
      end

      def rmp_concat(*args)
        args * ' || '
      end

      def rmp_char_length(column)
        "char_length(#{column})"
      end

      def rmp_substring(column, start_index, length)
        "substring(#{column} from #{start_index} for #{length})"
      end

      def rmp_current_time
        'NOW()'
      end

      def rmp_days_diff(start_date, end_date)
        "DATE_PART('day', (#{end_date})::date - (#{start_date})::date)"
      end

      def rmp_seconds_diff(start_date, end_date)
        "EXTRACT(EPOCH FROM (#{end_date})::timestamp - (#{start_date})::timestamp)"
      end

      def rmp_bool_to_int(field)
        "CAST(#{field} as INTEGER)"
      end

      def rmp_get_date(field)
        "(#{field})::timestamp::date"
      end

      def rmp_get_datetime(field)
        "(#{field})::timestamp"
      end

      def rmp_date_iso(field)
        "to_char((#{field})::date, 'YYYY-mm-dd')"
      end

      def rmp_add_month(field, num)
        "(#{field}::timestamp + '#{num} month'::interval)"
      end

      def rmp_add_days(field, days)
        "(#{field}::timestamp + '#{days} day'::interval)"
      end

      def rmp_add_seconds(field, secs)
        "(#{field}::timestamp + '#{secs} month'::interval)"
      end
    end
  end

  # Prepend scope (to multiple keys for example)
  # Naming: preload_scope_{association_name}
  # class SampleTableA < ActiveRecord::Base
  #   # id - integer
  #   # user_id - integer
  #   # has_many :sample_table_b, lambda { |*args|  if args.first }
  #   def self.preload_scope_sample_table_b(base_scope, preloader)
  #     scope.joins("INNER JOIN #{SampleTableA.table_name} sta ON sta.id = #{preloader.klass.table_name}.sample_table_a_id")
  #          .where("sta.user_id = #{preloader.klass.table_name}.user_id")
  #   end
  # end
  #
  # class SampleTableB < ActiveRecord::Base
  #   # id - integer
  #   # sample_table_a_id - integer
  #   # user_id - integer
  # end

  module Reflection
    class Preloader
      class Association
        module RMPlusPatch
          def query_scope(ids)
            if self.preload_scope.is_a?(Struct)
              func_name = "preload_scope_#{self.reflection.name}"
              if self.model && self.model.respond_to?(func_name)
                return self.model.send(func_name, super(ids), self)
              end
            end

            super(ids)
          end
        end

        prepend RMPlusPatch
      end
    end
  end

  class Relation
    module RMPlusPatch
      def exec_queries(*args)
        if @before_exec_callbacks.present?
          @before_exec_callbacks.each do |block|
            block.call
          end
        end

        records = super

        if @after_exec_callbacks.present?
          @after_exec_callbacks.each do |block|
            block.call(records)
          end
        end

        records
      end
    end

    def add_before_exec(&block)
      @before_exec_callbacks ||= []
      @before_exec_callbacks << block

      self
    end

    def add_after_exec(&block)
      @after_exec_callbacks ||= []
      @after_exec_callbacks << block

      self
    end

    prepend RMPlusPatch
  end

  class Base
    module RmPlusPatch
      def _write_attribute(attr_name, value)
        if value.is_a?(String) && value.present? && (self.class.columns_hash[attr_name].type == :string || self.class.columns_hash[attr_name].type == :text)
          value = value.chars.select { |ch| ch.bytesize <= 3 }.join
        end
        super(attr_name, value)
      end
    end

    prepend RmPlusPatch
  end
end

module Arel
  class Table
    attr_accessor :condition_over
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Attributes_Attribute o, collector
        join_name = o.relation.table_alias || o.relation.name
        if o.relation.respond_to?(:condition_over) && o.relation.condition_over.is_a?(Proc)
          res = o.relation.condition_over.call(o, "#{quote_table_name join_name}.#{quote_column_name o.name}").to_s
        else
          res = "#{quote_table_name join_name}.#{quote_column_name o.name}"
        end
        collector << res
      end
    end
  end
end

