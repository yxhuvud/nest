require "./spec_helper"

describe Nest do
  describe ".each_span" do
    it "ensures all child fibers complete before the span exits" do
      results = [] of Int32

      Nest.each_span do |pool|
        pool.spawn do
          sleep 10.milliseconds
          results << 1
        end

        pool.spawn do
          sleep 5.milliseconds
          results << 2
        end
      end

      results.size.should eq(2)
      results.should contain(1)
      results.should contain(2)
    end

    it "bubbles up the first exception thrown by a child fiber" do
      expect_raises(Exception, "Oops from child fiber") do
        Nest.each_span do |pool|
          pool.spawn do
            raise "Oops from child fiber"
          end
        end
      end
    end

    it "bubbles up exceptions thrown in the spawner block itself" do
      expect_raises(Exception, "Error in spawner block") do
        Nest.each_span do |pool|
          pool.spawn do
            sleep 5.milliseconds
          end
          raise "Error in spawner block"
        end
      end
    end

    it "swallows exceptions silently when bubble_exceptions is set to false" do
      executed = false

      Nest.each_span(bubble_exceptions: false) do |pool|
        pool.spawn do
          raise "This error should be ignored"
        end

        pool.spawn do
          sleep 5.milliseconds
          executed = true
        end
      end

      executed.should be_true
    end

    it "prioritizes the first encountered exception when both parent and child fail" do
      expect_raises(Exception, "Primary error") do
        Nest.each_span do |pool|
          pool.spawn do
            sleep 5.milliseconds
            raise "Secondary error from child"
          end
          raise "Primary error"
        end
      end
    end

    it "accepts a custom execution context passed into the span" do
      custom_context = Fiber::ExecutionContext::Concurrent.new "test"
      actual_context_inside_fiber = nil
      Nest.each_span(custom_context) do |pool|
        pool.spawn do
          actual_context_inside_fiber = Fiber::ExecutionContext.current
        end
      end

      actual_context_inside_fiber.should_not be_nil
      actual_context_inside_fiber.should eq(custom_context)
      actual_context_inside_fiber.should_not eq(Fiber::ExecutionContext.current)
    end
  end

  describe "Nest.map_span" do
    it "collects results from all child fibers into an array" do
      results = Nest.map_span(Int32) do |pool|
        pool.spawn do
          sleep 10.milliseconds
          10
        end

        pool.spawn do
          sleep 5.milliseconds
          20
        end
      end

      # Since fibers execute concurrently, order might be unordered in the array,
      # but all expected elements must be present.
      results.size.should eq(2)
      results.should contain(10)
      results.should contain(20)
    end

    it "bubbles up the first exception thrown by a child fiber by default and discards partial results" do
      expect_raises(Exception, "Oops from map child") do
        Nest.map_span(String) do |pool|
          pool.spawn do
            sleep 5.milliseconds
            "success"
          end

          pool.spawn do
            raise "Oops from map child"
          end
        end
      end
    end

    it "collects successful results and skips failed fibers when bubble_exceptions is false" do
      results = Nest.map_span(Int32, bubble_exceptions: false) do |pool|
        pool.spawn do
          raise "This error should be swallowed"
          100 # This won't be reached
        end

        pool.spawn do
          sleep 5.milliseconds
          200
        end
      end

      # The span should exit cleanly, returning only the value from the successful fiber
      results.should eq([200])
    end
  end
end
