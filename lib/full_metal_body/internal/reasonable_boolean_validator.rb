module FullMetalBody
  module Internal
    class ReasonableBooleanValidator < ActiveModel::EachValidator

      # ActiveRecord::Type::Boolean.new.castの条件が緩いのでやや厳しめにする。
      # trueを表す数字の1は、Formから渡ってくる場合は文字列の1なので、
      # TRUE_VALUESから数字の1は除外する。
      # 同じ理由で、FALSE_VALUESから数字の0も除外する。
      # FormやJSONからsymbolが渡ってくることはないので、それらも除外した。
      # @see https://shinkufencer.hateblo.jp/entry/2021/02/06/000000
      TRUE_VALUES = [true, "1", "t", "T", "true", "TRUE", "on", "ON"].to_set.freeze
      FALSE_VALUES = [false, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set.freeze

      def validate_each(record, attribute, value)
        unless [TRUE_VALUES, FALSE_VALUES].any? { |b| b.include?(value) }
          record.errors.add(attribute, :not_reasonable_boolean, value: value)
        end
      end

    end
  end
end
