require "./spec_helper"

describe Nest::Semaphore do
  it "will execute the thing if not blocked" do
    x = 0
    sem = Nest::Semaphore.new(2)
    sem.acquire do
      sem.acquire do
        x += 1
      end
      x += 1
    end

    x.should eq(2)
  end

  it "blocks when at capacity" do
    sem = Nest::Semaphore.new(1)
    order = [] of Int32
    channel = Channel(Nil).new

    sem.wait

    spawn do
      order << 1
      sem.wait
      order << 3
      channel.send(nil)
    end

    Fiber.yield

    order << 2
    sem.signal

    channel.receive
    order.should eq([1, 2, 3])
  end
end
