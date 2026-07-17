# iffywow Go SDK — test/coverage instrumentation (stdlib tooling only).

.PHONY: test test-race coverage coverage-html vet fmt check clean

test:
	go test ./...

test-race:
	go test -race ./...

coverage:
	go test -covermode=atomic -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out

coverage-html: coverage
	go tool cover -html=coverage.out -o coverage.html
	@echo "open coverage.html"

vet:
	go vet ./...

fmt:
	@files=$$(gofmt -l .); if [ -n "$$files" ]; then \
		echo "gofmt needed on:"; echo "$$files"; exit 1; fi

check: fmt vet test

clean:
	rm -f coverage.out coverage.html
