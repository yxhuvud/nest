require "wait_group"

module Nest
  class Pool(T, S)
    @exception : Exception? = nil
    @execution_context : Fiber::ExecutionContext

    def self.open(strategy : Strategy, execution_context = Fiber::ExecutionContext.current, &spawner_block : Pool(T, S) ->) forall S
      pool = Pool(T, S).new(execution_context, strategy)
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

    def initialize(@execution_context, @strategy : S)
      @wait_group = WaitGroup.new
      @mutex = Mutex.new
    end

    getter :execution_context, :wait_group, :mutex, :strategy

    protected def exception
      mutex.synchronize { @exception }
    end

    protected def report_exception(ex : Exception)
      mutex.synchronize do
        @exception ||= ex
      end
    end

    def spawn(&block : -> T)
      wait_group.add(1)

      execution_context.spawn do
        strategy.execute(self) { block.call }
        wait_group.done
      end
    end

    protected def wait_all
      wait_group.wait
    end
  end
end
