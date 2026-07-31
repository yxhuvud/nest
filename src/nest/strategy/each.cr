require "../strategy"

module Nest
  module Strategy
    # Strategy that does not care about the results.
    class Each
      include Strategy

      def initialize(@bubble_exceptions : Bool = true)
      end

      def execute(pool, &block)
        block.call
      rescue ex : Exception
        pool.report_exception(ex) if bubble_exceptions
      end

      def results
        nil
      end
    end
  end
end
