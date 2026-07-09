require "./nest/pool"

module Nest
  VERSION = "0.1.0"

  def self.span(execution_context = Fiber::ExecutionContext.current, &spawner_block : Pool ->)
    Pool.open(execution_context, &spawner_block)
  end
end
