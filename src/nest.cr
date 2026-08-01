require "./nest/pool"
require "./nest/strategy"

module Nest
  VERSION = "0.1.0"

  def self.each_span(execution_context = Fiber::ExecutionContext.current,
                     bubble_exceptions : Bool = true,
                     max_concurrency : Int32? = nil,
                     &spawner_block : Pool(Nil, Strategy::Each) ->)
    strategy = Strategy::Each.new(bubble_exceptions)
    Pool(Nil, Strategy::Each).open(strategy, execution_context, max_concurrency,  &spawner_block)
  end

  # Note: Order of results is not guaranteed!
  def self.map_span(type : T.class,
                    execution_context = Fiber::ExecutionContext.current,
                    max_concurrency : Int32? = nil,
                    capacity : Int32 = 64,
                    bubble_exceptions : Bool = true,
                    &spawner_block : Pool(T, Strategy::Map(T)) ->) forall T
    strategy = Strategy::Map(T).new(bubble_exceptions, capacity)
    Pool(T, Strategy::Map(T)).open(strategy, execution_context, max_concurrency, &spawner_block)
    strategy.results
  end
end
