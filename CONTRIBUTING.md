# Contributing to PoSh.FluidTemplateEngine

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## How to Contribute

### Reporting Bugs

Before submitting a bug report:

1. Check the [existing issues](https://github.com/jul-m/PoSh.FluidTemplateEngine/issues) to see if the problem has already been reported.
2. If not, [open a new issue](https://github.com/jul-m/PoSh.FluidTemplateEngine/issues/new?template=bug_report.md) using the bug report template.

Include as much detail as possible:
- PowerShell version (`$PSVersionTable`)
- .NET version (`dotnet --version`)
- Operating system
- Minimal reproduction steps
- Expected vs. actual behavior

### Suggesting Features

[Open a feature request](https://github.com/jul-m/PoSh.FluidTemplateEngine/issues/new?template=feature_request.md) using the feature request template. Describe the use case and expected behavior.

### Submitting Pull Requests

1. **Fork** the repository and create a branch from `main`.
2. **Build** and **test** your changes locally (see below).
3. **Follow** the coding conventions described in this document.
4. **Write or update tests** for any changed functionality.
5. **Submit** a pull request with a clear description of the changes.

## Versioning

The PowerShell module uses a **three‑digit version scheme** (`major.minor.patch`).

- The **major** and **minor** digits are derived from the version of `Fluid.Core` that
  the module is built against. For example, if the project references `Fluid.Core
  2.31.x`, the module version will start with `2.31`.
- The **patch** digit is incremented for each release of *this* repository that
  does not change the `Fluid.Core` dependency. It resets to `0` whenever the
  `Fluid.Core` version is bumped, reflecting that a new upstream API surface may
  require a new baseline.

This scheme keeps module versions aligned with the underlying engine while
allowing independent hot‑fixes and improvements.

## Development Setup

### Prerequisites

- [PowerShell 7.0+](https://github.com/PowerShell/PowerShell)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Pester 5](https://pester.dev/) (for running tests)

### Building

All workflows go through `run.ps1`:

```powershell
# Build and package the module
pwsh -NonInteractive ./run.ps1 -Mode Package

# The packaged module is output to: out/publish/PoSh.FluidTemplateEngine/
```

### Running Tests

```powershell
# Build first, then run tests
pwsh -NonInteractive ./run.ps1 -Mode Package
pwsh -NonInteractive ./run.ps1 -Mode Tests
```

Requires Pester 5 to be installed. Test helpers are included in `tests/_pwsh.tests.tools.ps1`.

### Generating Documentation

```powershell
pwsh -NonInteractive ./run.ps1 -Mode Documentation
```

Requires the [PoSh.CmdletDoc](https://github.com/jul-m/PoSh.CmdletDoc) module to be installed or available in your `$env:PSModulePath`.

## Coding Conventions

### C# (src/)

- **Namespace**: `PoSh.FluidTemplateEngine.Cmdlets` for cmdlets, `PoSh.FluidTemplateEngine.Core` for internal logic.
- **Cmdlet naming**: `[Verb][Noun]Cmdlet.cs` → PowerShell `Verb-Noun` (e.g., `FormatLiquidStringCmdlet.cs` → `Format-LiquidString`).
- **XML doc comments**: Written in **French** (they generate the PowerShell help content via `XmlDoc2CmdletDoc`).
- **Async bridging**: Fluid async calls are bridged synchronously with `.GetAwaiter().GetResult()`.
- **Error handling**: Use `ThrowTerminatingError` for parse failures, `WriteError` for runtime issues.
- **Nullable**: Enabled project-wide. Handle nullability properly.

### PowerShell (tests/, examples/)

- Use `Should -BeExactly` for string comparisons in Pester tests.
- Test files follow `Verb-Noun.Tests.ps1` naming (e.g., `Format-LiquidString.Tests.ps1`).
- Each test file starts with `BeforeAll { Initialize-TestEnvironment }`.
- Reset config with `Set-FluidModuleConfig -Reset` per `Describe` block.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new parameter to Format-LiquidString
fix: handle null model in PsModelConverter
docs: update installation instructions
test: add tests for strict filter validation
chore: update Fluid.Core to 2.32.0
```

## Project Structure

```
├── src/                           # C# source code
│   ├── Cmdlets/                   # One PSCmdlet class per cmdlet
│   └── Core/                      # Internal engine & utilities
├── tests/                         # Pester 5 tests
├── examples/                      # Usage examples
├── docs/                          # Documentation (English)
│   └── Cmdlets/                   # Auto-generated cmdlet reference
├── .github/                       # GitHub templates and workflows
└── run.ps1                        # Build/test/docs orchestrator
```

## Adding a New Cmdlet

1. Create `src/Cmdlets/{Verb}{Noun}Cmdlet.cs` inheriting `PSCmdlet`.
2. Add `[Cmdlet(Verbs*.Verb, "Noun")]` and `[OutputType]` attributes.
3. Write XML doc comments in French with `<example>` blocks.
4. Delegate core logic to `FluidManager` or a new `Core/` class.
5. Add corresponding `tests/{Verb}-{Noun}.Tests.ps1`.
6. Rebuild (`-Mode Package`) and regenerate docs (`-Mode Documentation`).

## Adding a Custom Extension (Filter / Tag / Block / Operator)

Custom extensions are registered via `Register-Liquid{Filter|Tag|Block|Operator}` cmdlets, which store `ScriptBlock` delegates in `FluidManager`'s static dictionaries. Registering invalidates the engine cache. Three tag/block variants exist: `Empty`, `Identifier`, `Expression` (see `LiquidTagType` enum).

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
