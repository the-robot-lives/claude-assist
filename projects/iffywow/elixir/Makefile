# iffywow Elixir SDK — test/coverage instrumentation.
# Coverage uses the built-in :cover integration (mix test --cover);
# threshold configured in mix.exs (test_coverage: [summary: [threshold: 80]]).

.PHONY: test coverage coverage-export lint fmt check clean

test:
	mix test

coverage:
	mix test --cover

# Export raw .coverdata (mergeable across partitions with `mix test.coverage`)
coverage-export:
	mix test --cover --export-coverage default

lint:
	mix compile --warnings-as-errors

fmt:
	mix format --check-formatted

check: fmt lint test

clean:
	rm -rf _build cover
