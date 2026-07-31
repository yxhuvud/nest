require "wait_group"
require "./semaphore"

module Nest
  class Pool(T, S)
    @exception : Exception? = nil
    @execution_context : Fiber::ExecutionContext
    @backpressure_semaphore : Semaphore?

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

    def initialize(@execution_context, @strategy : S, max_concurrency : Int? = nil)
      @wait_group = WaitGroup.new
      @mutex = Mutex.new
      if max_concurrency
        @backpressure_semaphore = Semaphore.new(max_concurrency)
      end
    end

    getter :execution_context, :wait_group, :mutex, :strategy, :backpressure_semaphore

    protected def exception
      mutex.synchronize { @exception }
    end

    protected def report_exception(ex : Exception)
      mutex.synchronize do
        @exception ||= ex
      end
    end

    def spawn(&block : -> T)
      if backpressure = @backpressure_semaphore
        backpressure.acquire { internal_spawn(block) }
      else
        internal_spawn(block)
      end
    end

    protected def internal_spawn(block : -> T)
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
