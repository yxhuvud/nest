# nest

Structured concurrency for Crystal fibers.

`nest` provides a small wrapper around [`Fiber::ExecutionContext`](https://crystal-lang.org/api/latest/Fiber/ExecutionContext.html) for spawning fibers with a well-defined lifetime.

A span doesn't return until all of its child fibers have completed.
Exceptions from child fibers are propagated by default, and an
optional concurrency limit provides back-pressure.

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  nest:
    github: yxhuvud/nest
```

Then run:

```sh
shards install
```

## API

The main entry points are:

```crystal
Nest.each_span(...)
Nest.map_span(...)
```

Both support:

* a custom `Fiber::ExecutionContext`
* `max_concurrency` for back-pressure
* `bubble_exceptions` to control exception propagation

## Usage

Require `nest`:

```crystal
require "nest"
```

### Spawning fibers

Use `each_span` when you don't need to collect results:

```crystal
Nest.each_span do |pool|
  pool.spawn { do_work }
  pool.spawn { do_other_work }
end
```

The span waits for both fibers to finish before returning.

This makes the lifetime of spawned work explicit:

```crystal
Nest.each_span do |pool|
  pool.spawn { use_resource }
end

resource.close
```

`resource.close` cannot run until the child fiber has finished.

### Collecting results

Use `map_span` to collect values from child fibers:

```crystal
values = Nest.map_span(Int32) do |pool|
  pool.spawn { 1 }
  pool.spawn { 2 }
  pool.spawn { 3 }
end
```

The order of the returned values is not guaranteed.

### Back-pressure

Limit the number of fibers in flight with `max_concurrency`:

```crystal
Nest.each_span(max_concurrency: 4) do |pool|
  items.each do |item|
    pool.spawn { process(item) }
  end
end
```

When the limit is reached, `spawn` waits for a running fiber to finish before accepting more work.

This is useful for preventing an unbounded producer from creating an unbounded amount of concurrent work.

### Exceptions

Exceptions raised by child fibers are propagated when the span exits:

```crystal
Nest.each_span do |pool|
  pool.spawn { raise "boom" }
end
```

If independent failures are acceptable, exception bubbling can be disabled:

```crystal
Nest.each_span(bubble_exceptions: false) do |pool|
  pool.spawn { might_fail }
  pool.spawn { keep_going }
end
```

For `map_span`, failed fibers are omitted when exception bubbling is disabled.

## Execution contexts

By default, `nest` uses the current execution context.

A different `Fiber::ExecutionContext` can be supplied when needed:

```crystal
context = Fiber::ExecutionContext::Concurrent.new("workers")

Nest.each_span(context) do |pool|
  pool.spawn { do_work }
end
```

`nest` does not replace Crystal's scheduler or impose a scheduling strategy. It only provides structured lifetime and coordination around the execution context you choose.

## Why?

Unstructured `spawn` makes it easy for work to outlive the operation that created it:

```crystal
spawn { do_work }

# Is do_work finished here?
```

With `nest`, the boundary is explicit:

```crystal
Nest.each_span do |pool|
  pool.spawn { do_work }
end

# do_work is finished here.
```

This follows the principles of [structured concurrency](https://vorpus.org/blog/notes-on-structured-concurrency-or-go-statement-considered-harmful/): child work belongs to the scope that created it.

This makes it easier to:

 - reason about the lifetime of concurrent work
 - safely use resources owned by the surrounding scope
 - propagate errors instead of silently losing exceptions in fibers

## Related work

`nest` is inspired by the structured-concurrency experiments in [`nested_scheduler`](https://github.com/yxhuvud/nested_scheduler).

Unlike `nested_scheduler`, `nest` does not replace Crystal's scheduler or manage its own thread pool. It builds on `Fiber::ExecutionContext` and `WaitGroup`s instead.

## Development

```sh
git clone https://github.com/yxhuvud/nest.git
cd nest
make
```


## Contributors

- [Linus Sellberg](https://github.com/your-github-user) - creator and maintainer
