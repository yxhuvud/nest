require "./strategy/*"

module Nest
  module Strategy
    getter bubble_exceptions : Bool

    abstract def execute(pool, &block)
  end
end
