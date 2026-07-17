# iffywow Python reference SDK — test/coverage instrumentation.
# Coverage config lives in pyproject.toml ([tool.coverage.*], fail_under=85).

PY ?= python3

.PHONY: deps test coverage coverage-html coverage-xml check clean

deps:
	$(PY) -m pip install -e ".[dev]"

test:
	$(PY) -m pytest

coverage:
	$(PY) -m coverage run -m pytest
	$(PY) -m coverage report

coverage-html: coverage
	$(PY) -m coverage html
	@echo "open htmlcov/index.html"

coverage-xml: coverage
	$(PY) -m coverage xml

check: test

clean:
	rm -rf .pytest_cache htmlcov .coverage coverage.xml build *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
