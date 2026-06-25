# Project Layout

GenAI Local — an Elixir extension library for running local LLM models via `ex_llama`.

```
genai_local/
├── lib/                            # Application source code → [layout/lib.md](layout/lib.md)
│   ├── local_llama/                #   Provider modules and manager
│   └── application.ex              #   OTP application entry point
├── config/                         # Mix environment configuration
│   ├── config.exs                  #   Shared config
│   ├── dev.exs                     #   Dev overrides
│   └── test.exs                    #   Test overrides
├── priv/                           # Runtime assets
│   └── local_llama/tiny_llama/     #   Bundled TinyLlama model + init script
├── test/                           # Test suites
│   ├── support/                    #   Shared test helpers
│   ├── local_llama_test.exs        #   Main test file
│   └── test_helper.exs             #   Test bootstrap
├── doc/                            # Generated ExDoc output (gitignored content)
├── .tool-versions                  # asdf — Erlang 28.4, Elixir 1.19.5, Node 20, cmake
├── .formatter.exs                  # Elixir formatter config
├── .gitignore                      # Git ignore rules
├── mix.exs                         # Project definition, deps, package config
├── mix.lock                        # Dependency lock file
├── BOOK.md                         # Extended documentation / guide
├── CHANGELOG.md                    # Release history
├── CONTRIBUTING.md                 # Contribution guidelines
├── TODO.md                         # Planned work
├── LICENSE                         # MIT license
└── README.md                       # Start here
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.tool-versions` | Install runtimes via `asdf install` |
| `priv/local_llama/tiny_llama/init.sh` | Run to download the TinyLlama GGUF model |
