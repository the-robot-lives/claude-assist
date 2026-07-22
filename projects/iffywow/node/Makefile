# iffywow Node SDK — test/coverage instrumentation.
# Uses Node's built-in test runner + coverage (no dev dependencies).
# Text summary works on Node >= 20; lcov reporter needs Node >= 22.

NODE ?= node

.PHONY: test coverage coverage-lcov check clean

test:
	$(NODE) --test test/

coverage:
	$(NODE) --test --experimental-test-coverage test/

coverage-lcov:
	mkdir -p coverage
	$(NODE) --test --experimental-test-coverage \
		--test-coverage-reporter=lcov \
		--test-coverage-reporter-destination=coverage/lcov.info test/
	@echo "wrote coverage/lcov.info"

check: test

clean:
	rm -rf coverage
