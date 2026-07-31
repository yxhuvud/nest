module Nest
  class Semaphore
    def initialize(@capacity : Int32)
      raise ArgumentError.new("Capacity must be greater than 0") if capacity <= 0

      @lock = Crystal::SpinLock.new
      @waiting_fibers = Deque(Fiber).new
    end

    # Decrements the semaphore. Suspends the calling fiber if no capacity is available.
    def wait : Nil
      @lock.lock
      if @capacity > 0
        @capacity -= 1
        @lock.unlock
      else
        @waiting_fibers.push(Fiber.current)
        @lock.unlock
        Fiber.suspend
      end
    end

    # Increments the semaphore. Wakes up the next waiting fiber if any exist.
    def signal : Nil
      @lock.lock
      if @waiting_fibers.empty?
        @capacity += 1
        @lock.unlock
      else
        next_fiber = @waiting_fibers.shift
        @lock.unlock
        next_fiber.enqueue
      end
    end

    # Concurrency wrapper utility
    def acquire(&)
      wait
      yield
    ensure
      signal
    end
  end
end
