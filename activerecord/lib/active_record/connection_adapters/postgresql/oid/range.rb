module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Range < Type::Value
          attr_reader :subtype, :type

          def initialize(subtype, type)
            @subtype = subtype
            @type = type
          end

          def extract_bounds(value)
            from, to = value[1..-2].split(',')
            {
              from:          (value[1] == ',' || from == '-infinity') ? @subtype.infinity(negative: true) : from,
              to:            (value[-2] == ',' || to == 'infinity') ? @subtype.infinity : to,
              exclude_start: (value[0] == '('),
              exclude_end:   (value[-1] == ')')
            }
          end

          def infinity?(value)
            value.respond_to?(:infinite?) && value.infinite?
          end

          def type_cast_single(value)
            infinity?(value) ? value : @subtype.type_cast(value)
          end

          def cast_value(value)
            return if value == 'empty'
            return value if value.is_a?(::Range)

            extracted = extract_bounds(value)
            from = type_cast_single extracted[:from]
            to = type_cast_single extracted[:to]

            if !infinity?(from) && extracted[:exclude_start]
              if from.respond_to?(:succ)
                from = from.succ
                ActiveSupport::Deprecation.warn <<-MESSAGE
Excluding the beginning of a Range is only partialy supported through `#succ`.
This is not reliable and will be removed in the future.
                MESSAGE
              else
                raise ArgumentError, "The Ruby Range object does not support excluding the beginning of a Range. (unsupported value: '#{value}')"
              end
            end
            ::Range.new(from, to, extracted[:exclude_end])
          end
        end
      end
    end
  end
end
