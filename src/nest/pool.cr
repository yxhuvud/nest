require "wait_group"

module Nest
  class Pool
    @exception : Exception? = nil
    @execution_context : Fiber::ExecutionContext

    def self.open(execution_context = Fiber::ExecutionContext.current, &spawner_block : Pool ->)
      pool = Pool.new(execution_context)
      begin
        spawner_block.call(pool)
      rescue ex : Exception
        # Ensuring that it nests correctly without leaving crap
        # left if main block crashes.
        pool.report_exception(ex)
      ensure
        pool.wait_all
        if ex = pool.exception
          # TODO: Stitch exception backtrace
          raise ex
        end
      end
    end

    def initialize(@execution_context)
      @wait_group = WaitGroup.new
      @mutex = Mutex.new
    end

    getter :execution_context, :wait_group, :mutex

    protected def exception
      mutex.synchronize { @exception }
    end

    protected def report_exception(ex : Exception)
      mutex.synchronize do
        @exception ||= ex
      end
    end

    def spawn(&block)
      wait_group.add(1)

      execution_context.spawn do
        begin
          block.call
        rescue ex : Exception
          report_exception(ex)
        ensure
          wait_group.done
        end
      end
    end

    protected def wait_all
      wait_group.wait
    end
  end
end
