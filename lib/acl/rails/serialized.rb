module ActiveRecord
  module Type
    class Serialized
      module RMPlusPatch
        def deserialize(value)
          vl = super
          if vl.respond_to?(:to_unsafe_hash)
            vl = vl.to_unsafe_hash
          end
          vl
        end

        def serialize(value)
          if value.respond_to?(:to_unsafe_hash)
            value = value.to_unsafe_hash
          end

          super(value)
        end
      end

      prepend RMPlusPatch
    end
  end
end