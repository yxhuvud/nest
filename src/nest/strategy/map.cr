require "../strategy"

module Nest
  module Strategy
    class Map(T)
      include Strategy

      def initialize(@bubble_exceptions : Bool = true)
        @results = [] of T
        @mutex = Mutex.new
      end

      def execute(pool, &block : -> T) : Nil
        value = block.call
        @mutex.synchronize { @results << value }
      rescue ex : Exception
        pool.report_exception(ex) if bubble_exceptions
      end

      def results : Array(T)
        @results
      end
    end
  end
end
