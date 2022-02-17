# frozen_string_literal: true

module FullMetalBody
  module DeepSort

    class Error < StandardError; end

    refine Hash do
      def deep_sort
        keys = self.keys
        raise DeepSort::Error, "Invalid Keys(#{keys})" unless keys.all? { |k| k.is_a?(String) || k.is_a?(Symbol) || k.is_a?(Numeric) }

        sort.to_h.transform_values { |v| v.respond_to?(:deep_sort) ? v.deep_sort : v }
      end

      def deep_sort!
        replace(deep_sort)
      end
    end

    refine Array do
      def deep_sort
        case
        when all?(Numeric) then sort
        when all?(String), all?(Symbol) then map(&:to_s).sort
        else
          map { |v| v.respond_to?(:deep_sort) ? v.deep_sort : v }.sort_by(&:to_s)
        end
      end

      def deep_sort!
        case
        when all?(Numeric) then sort!
        when all?(String), all?(Symbol) then map!(&:to_s).sort!
        else
          map! { |v| v.respond_to?(:deep_sort!) ? v.deep_sort! : v }.sort_by!(&:to_s)
        end
      end
    end

  end

end
