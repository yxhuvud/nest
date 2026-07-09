require "./spec_helper"

describe Nest do
  it "ensures all child fibers complete before the span exits" do
    results = [] of Int32

    Nest.span do |pool|
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
      Nest.span do |pool|
        pool.spawn do
          raise "Oops from child fiber"
        end
      end
    end
  end

  it "bubbles up exceptions thrown in the spawner block itself" do
    expect_raises(Exception, "Error in spawner block") do
      Nest.span do |pool|
        pool.spawn do
          sleep 5.milliseconds
        end
        raise "Error in spawner block"
      end
    end
  end

  it "prioritizes the first encountered exception when both parent and child fail" do
    expect_raises(Exception, "Primary error") do
      Nest.span do |pool|
        pool.spawn do
          raise "Secondary error from child"
        end
        raise "Primary error"
      end
    end
  end

  it "accepts a custom execution context passed into the span" do
    custom_context = Fiber::ExecutionContext::Concurrent.new "test"
    actual_context_inside_fiber = nil
    Nest.span(custom_context) do |pool|
      pool.spawn do
        actual_context_inside_fiber = Fiber::ExecutionContext.current
      end
    end

    actual_context_inside_fiber.should_not be_nil
    actual_context_inside_fiber.should eq(custom_context)
    actual_context_inside_fiber.should_not eq(Fiber::ExecutionContext.current)
  end
end
