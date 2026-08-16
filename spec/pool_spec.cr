require "./spec_helper"

private def raise_error
  raise "boom"
end

private def inner_pool
  strategy = Nest::Strategy::Each.new(true)
  Nest::Pool(Void, Nest::Strategy::Each).open(strategy) do |pool|
    pool.spawn { raise_error }
  end
end

private def outer_pool
  strategy = Nest::Strategy::Each.new(true)

  Nest::Pool(Nil, Nest::Strategy::Each).open(strategy) do |pool|
    pool.spawn { inner_pool }
  end
end

describe Nest::Pool do
  it "stitches the backtrace when reraising an exception" do
    ex = expect_raises(Exception, "boom") do
      inner_pool
    end

    backtrace = ex.backtrace.join("\n")

    backtrace.should contain("raise_error")
    backtrace.should contain("inner_pool")
  end

  it "stitches through nested pools" do
    ex = expect_raises(Exception, "boom") do
      outer_pool
    end

    backtrace = ex.backtrace.join("\n")

    raise_index = backtrace.index!("raise_error")
    inner_index = backtrace.index!("inner_pool")
    outer_index = backtrace.index!("outer_pool")

    raise_index.should be < inner_index
    inner_index.should be < outer_index
  end
end
