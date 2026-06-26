# The Robot Dissassembles

> An Apple Silicon decompiler that translates ARM64 machine code → assembly → pseudo-code → target programming languages using LLM-assisted semantic analysis

---

## Overview

**The Robot Dissassembles** is a macOS-native decompilation tool designed specifically for Apple Silicon (ARM64) architecture. It implements a multi-stage compilation pipeline that transforms raw machine code into human-readable target languages through an intermediate pseudo-language layer enhanced by large language models.

### Core Pipeline

```
Machine Code (ARM64)
    ↓ [Binary Parser]
Assembly Instructions
    ↓ [Control Flow Analysis]
Pseudo-Code (High-Level)
    ↓ [LLM Semantic Enhancement]
Target Language (Python/Rust/Go/etc.)
```

### What Makes This Different

Traditional decompilers (like Ghidra, IDA Pro) focus on accurate binary analysis but struggle with **semantic intent** — they can tell you *what* code does, but not *why* it does it. The Robot Dissassembles adds an LLM layer between assembly and target code to:

- **Infer variable names and types** from usage patterns
- **Detect idioms and patterns** (hashing, encryption, compression)
- **Generate descriptive comments** and function summaries
- **Preserve architectural meaning** in the final output

---

## Technical Architecture

### Platform Requirements

- **Operating System:** macOS 11.0+ (Big Sur or later)
- **Architecture:** Apple Silicon (M1, M2, M3, or later)
- **Runtime:** .NET 8.0 or later (for C# implementation)

### Technology Stack

```
Language: C# (.NET 8)
Parsing: Capstone disassembler engine
Data Flow: Soot-style points-to analysis
LLM Integration: Claude API (Azure-hosted)
Frontend: Terminal/TUI (Textual) + optional GUI
```

### Input Formats

| Format | Support Status | Notes |
|--------|----------------|-------|
| Mach-O (Universal 2) | ✅ Planned | Primary target |
| Mach-O (ARM64 slice) | ✅ Planned | Direct ARM64 binaries |
| Raw Hex Dumps | ✅ Planned | For embedded/analysis |
| Shared Libraries (.dylib) | ✅ Planned | Full symbol resolution |
| Kernel Extensions (.kext) | 🔮 Future | Requires special handling |
| Apple Silicon Binaries | ✅ Primary | Native ARM64 only |

### Supported Architectures

| Architecture | Status | Notes |
|--------------|--------|-------|
| ARM64 (AArch64) | ✅ Primary | Apple Silicon native mode |
| ARM64e (PAC+BTI) | 🔮 Future | Pointer authentication |
| ARMv8.3 | 🔮 Future | Vector instructions |
| ARMv9.0 | 🔮 Future | Scalable Vector Extension |

---

## Project Status

**Phase: Initial Design** 🎨

This is currently a proof-of-concept project in early stages. The core concept and architecture are defined, but implementation is not yet underway.

### Implemented

- ✅ Project brief and architecture doc
- ✅ Technical requirements analysis
- ✅ TODO: None (project is pre-implementation)

### Planned Development Phases

| Phase | Focus | Status | Timeline |
|-------|-------|--------|----------|
| **Phase 0** | Prototype disassembler | 📋 Not Started | Q3 2026 |
| **Phase 1** | Assembly → Pseudo-code | 📋 Not Started | Q4 2026 |
| **Phase 2** | LLM integration | 📋 Not Started | Q1 2027 |
| **Phase 3** | Target language codegen | 📋 Not Started | Q2 2027 |
| **Phase 4** | UI/UX & polishing | 📋 Not Started | Q3 2027 |

---

## How It Works

### Stage 1: Binary Parsing

The tool accepts Mach-O binaries and extracts:

- **Load commands** (segments, sections, dylibs entry points)
- **Code sections** (`__TEXT,__text`, `__TEXT,__stubs`, etc.)
- **Symbol tables** (imported/exported symbols)
- **Relocations** (address fixups and references)
- **Entitlements** (code signing, platform-specific metadata)

```csharp
// Pseudo-code for Mach-O parsing
var binary = MachOParser.Parse("/path/to/binary");
var textSection = binary.GetSection("__TEXT", "__text");
var bytes = textSection.ExtractBytes();
```

### Stage 2: Disassembly → Assembly

Using the Capstone engine, raw bytes are decoded into ARM64 instructions:

```
0x100001000:  D2800020    mov     x0, #0x1
0x100001004:  12800040    mov     w0, #0x4
0x100001008:  94000001    bl      #0x100001010
0x10000100C:  D65F03C0    ret
```

### Stage 3: Control Flow Analysis

Builds a **Control Flow Graph (CFG)** to identify:

- Basic blocks (sequences without branches)
- Jump targets and loop structures
- Function boundaries and call sites
- Data dependencies between instructions

```
Basic Block #1: 0x100001000 - 0x10000100C
    └─> call @0x100001010
    └─> ret
```

### Stage 4: Pseudo-Code Generation

Translates assembly into language-agnostic pseudo-code:

```python
# Pseudo-code representation
func_0x100001000:
    x0 = 1
    w0 = 4
    call func_0x100001010(x0, w0)
    return x0
```

### Stage 5: LLM Semantic Enhancement

Passes the pseudo-code through an LLM to:

1. **Infer variable names** from usage:
   ```python
   # Before LLM
   x0 = 1
   w0 = 4

   # After LLM
   num_items = 1
   max_attempts = 4
   ```

2. **Detect patterns** and add semantic context:
   - Hashing functions → `compute_sha256(data)`
   - Encryption calls → `encrypt_aes128(key, iv, plaintext)`
   - Compression → `compress_zlib(input_buffer)`

3. **Generate documentation**:
   ```python
   """
   Validates and processes user input.

   Args:
       num_items: Number of items to process (must be > 0)
       max_attempts: Maximum retry attempts for validation

   Returns:
       Status code indicating success or failure.
   """
   ```

### Stage 6: Target Language Codegen

Final output in programmer-friendly languages:

```python
# Python output
def validate_input(num_items: int, max_attempts: int) -> int:
    """
    Validates and processes user input.

    Args:
        num_items: Number of items to process (must be > 0)
        max_attempts: Maximum retry attempts for validation

    Returns:
        Status code indicating success or failure.
    """
    status = perform_validation(num_items, max_attempts)
    return status
```

```rust
// Rust output
fn validate_input(num_items: u64, max_attempts: u32) -> i32 {
    /// Validates and processes user input.
    ///
    /// # Arguments
    /// * `num_items` - Number of items to process (must be > 0)
    /// * `max_attempts` - Maximum retry attempts for validation
    ///
    /// # Returns
    /// Status code indicating success or failure.
    let status = perform_validation(num_items, max_attempts);
    status
}
```

---

## Use Cases

### Security Research

- **Vulnerability analysis:** Understand patched vulnerabilities by decompiling security updates
- **Malware analysis:** Reverse-engineer ARM64 macOS malware without source code
- **Security audits:** Review closed-source SDKs and frameworks compliance

### Software Interoperability

- **Format translation:** Convert ARM64 binaries to readable code for documentation
- **Legacy support:** Understand deprecated APIs in modern applications
- **Cross-platform porting:** Extract algorithms from macOS apps for other platforms

### Education & Research

- **Assembly learning:** Study real-world ARM64 code patterns
- **Compiler research:** Analyze how compilers generate machine code
- **Algorithm extraction:** Recover implemented data structures and algorithms

### Reverse Engineering

- **Protocol analysis:** Recover network protocols from encrypted applications
- **Key extraction:** Find encryption keys and secrets in memory dumps
- **API discovery:** Map undocumented or hidden APIs in Apple frameworks

---

## Getting Started (When Ready)

### Prerequisites

```bash
# Install .NET 8 SDK
brew install dotnet-sdk

# Install Capstone disassembler (via Homebrew)
brew install capstone

# Clone the repository
git clone https://github.com/your-org/therobotdisassembles.git
cd therobotdisassembles
```

### Building

```bash
# Restore dependencies
dotnet restore

# Build the solution
dotnet build

# Run tests
dotnet test
```

### Basic Usage

```bash
# Decompile a binary to Python
./therobotdisassembles decompile \
  --input /path/to/binary \
  --output ./decompiled \
  --target-language python

# Generate control flow graph visualization
./therobotdisassembles cfg \
  --input /path/to/binary \
  --output ./cfg.dot

# Interactive mode with TUI
./therobotdisassembles interactive /path/to/binary
```

---

## Project Structure (Planned)

```
therobotdisassembles/
├── src/
│   ├── TherobotDissassembles.Core/      # Core decompilation engine
│   │   ├── Parsing/                     # Mach-O binary parsing
│   │   ├── Disassembly/                 # Capstone wrapper
│   │   ├── ControlFlow/                 # CFG construction
│   │   ├── PseudoCode/                  # Intermediate representation
│   │   └── LLM/                         # Claude API integration
│   ├── TherobotDissassembles.TUI/       # Terminal UI (Textual)
│   ├── TherobotDissassembles.CLI/       # Command-line interface
│   └── TherobotDissassembles.GUI/       # Optional GUI (Avalonia)
├── tests/
│   ├── Unit tests for each module
│   ├── Integration tests with sample binaries
│   └── Regression test suite
├── docs/
│   ├── ARCHITECTURE.md
│   ├── MACHO_FORMAT.md
│   ├── LLM_INTEGRATION.md
│   └── TARGET_LANGUAGES.md
└── samples/
    ├── test-binaries/                   # Small binaries for testing
    └── known-bad/                       # Malware samples (restricted)
```

---

## Contributing

This project is currently in the **design phase**. When implementation begins:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Areas for Contribution

- **Binary parsing:** Improved Mach-O parsing edge cases
- **Disassembly:** Support for ARMv8.3+ and ARMv9 instructions
- **Control flow:** Better loop detection and optimization
- **LLM integration:** Custom prompts for better semantic analysis
- **Target languages:** New codegen targets (Java, Swift, Go)
- **Testing:** Automated test suite with real-world binaries
- **Documentation:** Examples, tutorials, and API docs

---

## License

**TBD** — To be determined when the project moves to active development.

---

## Related Projects

This project is part of the **The Robot** ecosystem:

- **[Therobotdrafts](../therobotdrafts/)** — Unity/VR UML-IDE for code visualization (`code → model`)
- **[Therobotmakes](../therobotmakes.com/)** — Design system and creative tools
- **[Therobotknows](../therobotknows.com/)** — Knowledge management and documentation

**Complementary Tools:**

- [Ghidra](https://ghidra-sre.org/) — Multi-architecture decompiler (Java-based)
- [IDA Pro](https://hex-rays.com/ida-pro/) — Commercial disassembler/decompiler
- [Radare2](https://rada.re/) — Reverse engineering framework
- [Hopper](https://www.hopperapp.com/) — macOS disassembler (non-ARM64)

---

## Roadmap

### Q3 2026 — Prototype

- [ ] Basic Mach-O parsing (load commands, sections)
- [ ] Capstone disassembler integration
- [ ] Simple instruction → assembler mapping
- [ ] Command-line skeleton

### Q4 2026 — Analysis Engine

- [ ] Control flow graph construction
- [ ] Basic block identification
- [ ] Function boundary detection
- [ ] Data flow analysis (SSA form)
- [ ] Pseudo-code generation

### Q1 2027 — LLM Integration

- [ ] Claude API integration
- [ ] Semantic enhancement pipeline
- [ ] Pattern detection library
- [ ] Variable name inference
- [ ] Comment and documentation generation

### Q2 2027 — Codegen & UI

- [ ] Python target language
- [ ] Rust target language
- [ ] Textual TUI for interactive analysis
- [ ] Configuration system for output customization

### Q3 2027 — Polish

- [ ] Additional target languages (Go, Swift, Java)
- [ ] Performance optimization
- [ ] GUI option (Avalonia)
- [ ] Documentation and examples
- [ ] Release v1.0

---

## Questions & Discussion

**For questions about this project:**

1. Open a [GitHub Discussion](https://github.com/your-org/therobotdisassembles/discussions)
2. Join the `#therobot` channel in the Noizu Discord
3. Read the [Architecture Doc](docs/ARCHITECTURE.md) for technical details

**For contributing or feature requests:**

1. Check existing [Issues](https://github.com/your-org/therobotdisassembles/issues)
2. Open a new Issue with the appropriate template
3. Tag with `enhancement`, `bug`, or `question`

---

## Contact

- **Author:** Keith Brings ([@keithbrings](https://github.com/keithbrings))
- **Email:** keith.brings@noizu.com
- **Project Home:** [therobotdisassembles.noizu.com](https://therobotdisassembles.noizu.com)

---

## Acknowledgments

This project draws inspiration from:

- **Ghidra** — Control flow analysis and SSA transformation
- **Radare2** — Binary parsing and disassembly
- **RetDec** — Intermediate representation approach
- **The Apple Security Bounty program** — For highlighting ARM64 reverse engineering needs

Special thanks to the LLVM and Capstone projects for providing solid disassembly foundations.

---

*Last Updated: 2026-06-26*
