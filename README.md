# PoSh.FluidTemplateEngine

[![CI](https://github.com/jul-m/PoSh.FluidTemplateEngine/actions/workflows/ci.yml/badge.svg)](https://github.com/jul-m/PoSh.FluidTemplateEngine/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoSh.FluidTemplateEngine?style=flat-square&label=PSGallery)](https://www.powershellgallery.com/packages/PoSh.FluidTemplateEngine)
[![PowerShell 7.0+](https://img.shields.io/badge/PowerShell-7.0+-blue?style=flat-square)](https://github.com/PowerShell/PowerShell)
[![.NET 8.0+](https://img.shields.io/badge/.NET-8.0+-512bd4?style=flat-square)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green?style=flat-square)](LICENSE)

A **PowerShell module** for easy rendering of [**Liquid**](https://shopify.github.io/liquid/) templates using the high-performance [**Fluid**](https://github.com/sebastienros/fluid) .NET library.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Cmdlets Reference](#cmdlets-reference)
- [Configuration](#configuration)
- [Custom Filters](#custom-filters)
- [Custom Tags](#custom-tags)
- [Custom Blocks](#custom-blocks)
- [Custom Operators](#custom-operators)
- [Functions & Macros](#functions--macros)
- [Whitespace Control](#whitespace-control)
- [Encoding](#encoding)
- [Type Registration (CLR Access)](#type-registration-clr-access)
- [Strict Modes](#strict-modes)
- [Include & Render](#include--render)
- [Advanced Configuration](#advanced-configuration)
- [Build & Development](#build--development)
- [Architecture](#architecture)
- [License](#license)

---

## Features

| Feature | Description |
|---------|-------------|
| **Liquid Rendering** | Full Liquid template engine (variables, filters, tags, loops, conditions) |
| **Compiled Templates** | One-shot or compile-then-render workflow for optimal performance |
| **File-Based Rendering** | Render templates from files with `{% include %}` / `{% render %}` support |
| **Custom Filters** | Register PowerShell ScriptBlock-based Liquid filters |
| **Custom Tags** | Register custom Liquid tags (Empty, Identifier, Expression) |
| **Custom Blocks** | Register custom Liquid blocks with body content |
| **Custom Operators** | Register custom binary comparison operators |
| **Functions & Macros** | Built-in support for `{% macro %}` and `{{ func() }}` syntax |
| **Parentheses** | Optional grouping of expressions with parentheses |
| **Strict Modes** | Strict variables and strict filters (including in includes) |
| **Whitespace Control** | Full trimming and greedy mode configuration |
| **CLR Type Access** | Allow-list .NET types for member access in templates |
| **Localization** | Culture and timezone support for dates/numbers |
| **HTML Encoding** | Optional HTML encoding on output |
| **Template Caching** | Fingerprint-based engine caching for optimal performance |

## Prerequisites

- **PowerShell 7.0+**
- **.NET 8.0+** runtime

## Installation

### From PowerShell Gallery

```powershell
Install-Module -Name PoSh.FluidTemplateEngine
```

### From Source (Development)

```powershell
# Build the module
pwsh -NonInteractive ./run.ps1 -Mode Package

# Import
Import-Module ./out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1 -Force
```

---

## Quick Start

### 1. One-Shot Rendering

```powershell
Format-LiquidString -Source 'Hello {{ name }}!' -Model @{ name = 'Alice' }
# Output: Hello Alice!
```

### 2. Compile + Render (Recommended for Repeated Use)

```powershell
$template = New-FluidTemplate -Source 'Hi {{ name }}, welcome!'
$template | Invoke-FluidTemplate -Model @{ name = 'Bob' }
# Output: Hi Bob, welcome!
```

### 3. Render from File with Includes

```powershell
Set-FluidModuleConfig -TemplateRoot './templates'
Invoke-FluidFile -Path './templates/main.liquid' -Model @{ title = 'Home' }
```

### 4. Complex Data Models

```powershell
$model = @{
    title = 'Products'
    items = @(
        @{ name = 'Widget'; price = 9.99 }
        @{ name = 'Gadget'; price = 24.95 }
    )
}

$source = @'
# {{ title }}
{% for item in items %}
- {{ item.name }}: ${{ item.price }}
{% endfor %}
'@

Format-LiquidString -Source $source -Model $model
```

---

## Cmdlets Reference

| Cmdlet | Description |
|--------|-------------|
| [`Format-LiquidString`](docs/Cmdlets/Format-LiquidString.md) | Parse + render a Liquid template in one step |
| [`New-FluidTemplate`](docs/Cmdlets/New-FluidTemplate.md) | Compile a Liquid template into a reusable object |
| [`Invoke-FluidTemplate`](docs/Cmdlets/Invoke-FluidTemplate.md) | Render a compiled template with a model |
| [`Invoke-FluidFile`](docs/Cmdlets/Invoke-FluidFile.md) | Render a Liquid template from a file |
| [`Get-FluidModuleConfig`](docs/Cmdlets/Get-FluidModuleConfig.md) | Display the current module configuration |
| [`Set-FluidModuleConfig`](docs/Cmdlets/Set-FluidModuleConfig.md) | Set module configuration options |
| [`Register-FluidType`](docs/Cmdlets/Register-FluidType.md) | Allow-list a .NET type for member access |
| [`Register-LiquidFilter`](docs/Cmdlets/Register-LiquidFilter.md) | Register a custom Liquid filter (ScriptBlock) |
| [`Register-LiquidTag`](docs/Cmdlets/Register-LiquidTag.md) | Register a custom Liquid tag |
| [`Register-LiquidBlock`](docs/Cmdlets/Register-LiquidBlock.md) | Register a custom Liquid block |
| [`Register-LiquidOperator`](docs/Cmdlets/Register-LiquidOperator.md) | Register a custom binary operator |

> Full auto-generated cmdlet documentation is available in [`docs/Cmdlets/`](docs/Cmdlets/).

---

## Configuration

Use `Set-FluidModuleConfig` to configure the module globally for the current session:

```powershell
# View current configuration
Get-FluidModuleConfig

# Reset to defaults
Set-FluidModuleConfig -Reset
```

### All Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-TemplateRoot` | `string` | `$PWD` | Root directory for `{% include %}` / `{% render %}` |
| `-StrictVariables` | `switch` | `$false` | Error on undefined variables |
| `-StrictFilters` | `switch` | `$false` | Error on unknown filters (including in includes) |
| `-UndefinedFormat` | `string` | `$null` | Fallback format for undefined variables (e.g. `[{name} not found]`) |
| `-MaxSteps` | `int` | `0` | Maximum execution steps (0 = unlimited) |
| `-MaxRecursion` | `int` | `$null` | Maximum recursion depth for includes/renders |
| `-AllowFunctions` | `switch` | `$false` | Enable function/macro syntax |
| `-AllowParentheses` | `switch` | `$false` | Enable expression grouping with parentheses |
| `-Culture` | `string` | `$null` | Culture for date/number formatting (e.g. `fr-FR`) |
| `-TimeZoneId` | `string` | `$null` | Time zone for date parsing (e.g. `Europe/Paris`) |
| `-Trimming` | `TrimmingFlags` | `None` | Automatic whitespace trimming rules |
| `-Greedy` | `bool` | `$true` | When true, trimming removes all successive blank chars |
| `-ModelNamesComparer` | `enum` | `OrdinalIgnoreCase` | How property names are compared |
| `-IgnoreMemberCasing` | `bool` | `$false` | Ignore case for CLR member access |
| `-JsonIndented` | `bool` | `$false` | Indented output for the `json` filter |
| `-JsonRelaxedEscaping` | `bool` | `$false` | Relaxed JSON escaping (UnsafeRelaxedJsonEscaping) |

---

## Custom Filters

Register PowerShell ScriptBlock-based Liquid filters using `Register-LiquidFilter`.
The ScriptBlock receives the input value as the first argument, followed by any filter arguments.

```powershell
# Simple filter
Register-LiquidFilter -Name 'shout' -ScriptBlock {
    param($input)
    $input.ToString().ToUpperInvariant()
}

Format-LiquidString -Source '{{ name | shout }}' -Model @{ name = 'hello' }
# Output: HELLO
```

```powershell
# Filter with arguments
Register-LiquidFilter -Name 'prefix' -ScriptBlock {
    param($input, $prefix)
    "$prefix$input"
}

Format-LiquidString -Source "{{ name | prefix: '>> ' }}" -Model @{ name = 'World' }
# Output: >> World
```

---

## Custom Tags

Tags are self-closing Liquid elements (no `{% end... %}`). Register them using `Register-LiquidTag`.

Three types are supported:

### Empty Tag — No Parameter

```powershell
Register-LiquidTag -Name 'timestamp' -Type Empty -ScriptBlock {
    (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

Format-LiquidString -Source 'Generated on {% timestamp %}' -Model @{}
# Output: Generated on 2026-02-28 14:30:00
```

### Identifier Tag — Takes an Identifier

```powershell
Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
    param($identifier)
    "Hello $identifier!"
}

Format-LiquidString -Source '{% hello world %}' -Model @{}
# Output: Hello world!
```

### Expression Tag — Takes an Evaluated Expression

```powershell
Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
    param($value)
    ">> $value <<"
}

Format-LiquidString -Source "{% echo 'test' | upcase %}" -Model @{}
# Output: >> TEST <<
```

---

## Custom Blocks

Blocks are Liquid elements with body content between `{% name %}...{% endname %}`. Register them using `Register-LiquidBlock`.

The ScriptBlock receives the rendered body as a string parameter.

### Empty Block — Wraps Content

```powershell
Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
    param($body)
    "<div class='card'>$body</div>"
}

Format-LiquidString -Source '{% card %}Important{% endcard %}' -Model @{}
# Output: <div class='card'>Important</div>
```

### Identifier Block — Named Wrapper

```powershell
Register-LiquidBlock -Name 'tag' -Type Identifier -ScriptBlock {
    param($identifier, $body)
    "<$identifier>$body</$identifier>"
}

Format-LiquidString -Source '{% tag section %}Content{% endtag %}' -Model @{}
# Output: <section>Content</section>
```

### Expression Block — Parameterized Block

```powershell
Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
    param($value, $body)
    $body * [int]$value
}

Format-LiquidString -Source '{% repeat 3 %}Go! {% endrepeat %}' -Model @{}
# Output: Go! Go! Go! 
```

---

## Custom Operators

Operators are used in `{% if %}` conditions to compare values. Register custom binary operators using `Register-LiquidOperator`.

The ScriptBlock receives `$left` and `$right` operands and must return a boolean.

```powershell
# XOR operator
Register-LiquidOperator -Name 'xor' -ScriptBlock {
    param($left, $right)
    [bool]$left -xor [bool]$right
}

Format-LiquidString -Source '{% if true xor false %}Yes{% endif %}' -Model @{}
# Output: Yes

Format-LiquidString -Source '{% if true xor true %}Yes{% else %}No{% endif %}' -Model @{}
# Output: No
```

```powershell
# Regex match operator
Register-LiquidOperator -Name 'matches' -ScriptBlock {
    param($left, $right)
    $left -match $right
}

Format-LiquidString -Source "{% if name matches '^A' %}Starts with A{% endif %}" -Model @{ name = 'Alice' }
# Output: Starts with A
```

---

## Functions & Macros

Fluid supports functions and macros when enabled via `AllowFunctions`.

### Enabling Functions

```powershell
Set-FluidModuleConfig -AllowFunctions
```

### Using Macros

Define reusable template fragments with `{% macro %}`:

```powershell
Set-FluidModuleConfig -AllowFunctions

$source = @'
{% macro greet(name, greeting='Hello') %}
{{ greeting }} {{ name }}!
{% endmacro %}

{{ greet('Alice') }}
{{ greet('Bob', greeting='Hi') }}
'@

Format-LiquidString -Source $source -Model @{}
```

### Importing Functions from External Templates

```liquid
{% from 'forms' import field %}

{{ field('user') }}
{{ field('pass', type='password') }}
```

---

## Whitespace Control

### Hyphens in Templates

Use hyphens (`-`) in tags and output values to strip whitespace:

```liquid
{%- assign name = "Bill" -%}
{{ name }}
```

### Automatic Trimming

Configure automatic whitespace trimming without hyphens:

```powershell
# Trim right side of tags and left side of output values
Set-FluidModuleConfig -Trimming TagRight, OutputLeft

# Disable greedy mode (only strip spaces before first newline)
Set-FluidModuleConfig -Greedy $false
```

**Available `TrimmingFlags`:** `None`, `TagLeft`, `TagRight`, `OutputLeft`, `OutputRight`, `TagBoth`, `OutputBoth`, `All`

### Greedy Mode

When enabled (default), trimming removes **all** successive blank characters. When disabled, only spaces before the first newline are stripped.

---

## Encoding

By default, output is **not encoded**. Use `-HtmlEncode` to activate HTML encoding:

```powershell
# No encoding (default)
Format-LiquidString -Source '{{ val }}' -Model @{ val = '<script>alert(1)</script>' }
# Output: <script>alert(1)</script>

# HTML encoded
Format-LiquidString -Source '{{ val }}' -Model @{ val = '<script>alert(1)</script>' } -HtmlEncode
# Output: &lt;script&gt;alert(1)&lt;/script&gt;
```

---

## Type Registration (CLR Access)

By default, Fluid only allows access to dictionary/hashtable properties. To use .NET objects in templates, register their types first:

```powershell
# Register all public properties
Register-FluidType -Type ([System.Version])

# Register specific properties only
Register-FluidType -TypeName 'System.Diagnostics.Process' -Member Id, ProcessName

# Use in templates
Register-FluidType -TypeName 'System.Version' -Member Major, Minor, Build
Format-LiquidString -Source '{{ v.Major }}.{{ v.Minor }}.{{ v.Build }}' -Model @{ v = [Version]'1.2.3' }
# Output: 1.2.3
```

### Case Sensitivity

```powershell
# Ignore casing on registered type members
Set-FluidModuleConfig -IgnoreMemberCasing $true
```

---

## Strict Modes

### Strict Variables

Error when accessing undefined variables:

```powershell
Set-FluidModuleConfig -StrictVariables
Format-LiquidString -Source '{{ missing }}' -Model @{} -ErrorAction Stop
# Throws: Undefined variable 'missing'
```

### Undefined Format (Fallback)

When strict variables is disabled, provide a fallback format for undefined variables:

```powershell
Set-FluidModuleConfig -UndefinedFormat '[{name} not found]'
Format-LiquidString -Source '{{ missing }}' -Model @{}
# Output: [missing not found]
```

### Strict Filters

Error when using unregistered filters (including in included templates):

```powershell
Set-FluidModuleConfig -StrictFilters
Format-LiquidString -Source "{{ 'hello' | unknown_filter }}" -Model @{} -ErrorAction Stop
# Throws: Undefined filter 'unknown_filter'
```

---

## Include & Render

Use `{% include %}` and `{% render %}` to embed partial templates:

```powershell
# Set the root directory for template resolution
Set-FluidModuleConfig -TemplateRoot './templates'

# Or specify per-call
Invoke-FluidFile -Path './templates/main.liquid' -Model $data -TemplateRoot './templates'
```

```liquid
<!-- main.liquid -->
{% include 'header' %}
<main>{{ content }}</main>
{% include 'footer' %}
```

> The template root is automatically inferred from the file's directory when using `Invoke-FluidFile`, unless explicitly overridden.

---

## Advanced Configuration

### Expression Grouping (Parentheses)

```powershell
Set-FluidModuleConfig -AllowParentheses

Format-LiquidString -Source '{{ 1 | plus: (2 | times: 3) }}' -Model @{}
# Output: 7
```

### Localization

```powershell
# Set culture for date/number formatting
Set-FluidModuleConfig -Culture 'fr-FR'
Format-LiquidString -Source '{{ 1234.56 }}' -Model @{}
```

### Time Zones

```powershell
Set-FluidModuleConfig -TimeZoneId 'Europe/Paris'
Format-LiquidString -Source "{{ 'now' | date: '%Y-%m-%d %H:%M' }}" -Model @{}
```

### JSON Options

```powershell
# Indented JSON output
Set-FluidModuleConfig -JsonIndented $true

# Relaxed escaping (no escaping of <, >, &, etc.)
Set-FluidModuleConfig -JsonRelaxedEscaping $true

Format-LiquidString -Source '{{ data | json }}' -Model @{ data = @{ key = 'value' } }
```

### Model Names Comparison

```powershell
# Case-sensitive property names
Set-FluidModuleConfig -ModelNamesComparer Ordinal
```

**Available modes:** `OrdinalIgnoreCase` (default), `Ordinal`, `InvariantCultureIgnoreCase`, `InvariantCulture`, `CurrentCultureIgnoreCase`, `CurrentCulture`

### Execution Limits

```powershell
# Limit template execution steps (prevent infinite loops)
Set-FluidModuleConfig -MaxSteps 100000

# Limit recursion depth for includes/renders
Set-FluidModuleConfig -MaxRecursion 20
```

---

## Build & Development

### Build

```powershell
# Build the module (compile + package)
pwsh -NonInteractive ./run.ps1 -Mode Package

# Generate cmdlet documentation
pwsh -NonInteractive ./run.ps1 -Mode Documentation

# Run tests
pwsh -NonInteractive ./run.ps1 -Mode Tests
```

### CI/CD

This project uses [GitHub Actions](.github/workflows/) for continuous integration:

- **[CI](.github/workflows/ci.yml)** — Builds and tests on every push/PR across Windows, macOS, and Linux.
- **[Release](.github/workflows/release.yml)** — Publishes to PowerShell Gallery and creates GitHub Releases on version tags (`v*`).

To publish a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```

> **Note:** Publishing to PSGallery requires a `PSGALLERY_API_KEY` secret in the `release` GitHub environment.

### Documentation

- **[Full Documentation](docs/README.md)** — Cmdlet reference and module information.
- **[Advanced Guide](docs/Advanced-Guide.md)** — Custom extensions, architecture, patterns, and recipes.
- **[Examples](examples/)** — Runnable example scripts.

### Project Structure

```
├── src/                           # C# source code
│   ├── Cmdlets/                   # PowerShell cmdlet implementations
│   │   ├── FormatLiquidStringCmdlet.cs
│   │   ├── NewFluidTemplateCmdlet.cs
│   │   ├── InvokeFluidTemplateCmdlet.cs
│   │   ├── InvokeFluidFileCmdlet.cs
│   │   ├── SetFluidModuleConfigCmdlet.cs
│   │   ├── GetFluidModuleConfigCmdlet.cs
│   │   ├── RegisterFluidTypeCmdlet.cs
│   │   ├── RegisterLiquidFilterCmdlet.cs
│   │   ├── RegisterLiquidTagCmdlet.cs
│   │   ├── RegisterLiquidBlockCmdlet.cs
│   │   └── RegisterLiquidOperatorCmdlet.cs
│   └── Core/                      # Internal engine & utilities
│       ├── FluidManager.cs        # Singleton engine (parser + options cache)
│       ├── FluidModuleConfiguration.cs
│       ├── PsModelConverter.cs    # PS → Fluid model bridge
│       ├── StrictFiltersValidator.cs  # AST Visitor for filter validation
│       ├── ValidatingTemplateCache.cs # Decorator for strict filter checks on includes
│       ├── CompiledFluidTemplate.cs
│       ├── ScriptBlockBinaryExpression.cs  # Custom operator support
│       └── ...
├── tests/                         # Pester tests
├── examples/                      # Usage examples
├── docs/                          # Generated documentation
├── assets/                        # Liquid templates for doc generation
├── lib/                           # Build helpers
└── run.ps1                        # Build/test/docs orchestrator
```

---

## Architecture

The module is a **binary PowerShell module** compiled from C# targeting .NET 8.

### Engine Lifecycle

1. **Configuration** is stored in a PowerShell global variable (`$Global:FluidModuleConfiguration`)
2. The **FluidParser** and **TemplateOptions** are lazily created and cached based on a fingerprint of all configuration values
3. When configuration changes, the engine is automatically rebuilt on next use
4. Custom filters, tags, blocks, and operators are stored independently and applied when the engine is rebuilt

### Key Design Decisions

- **Fingerprint-based caching** — The engine (parser + options) is only rebuilt when configuration actually changes
- **ScriptBlock bridge** — PowerShell ScriptBlocks are transparently wrapped into Fluid delegates for filters, tags, blocks, and operators
- **AST Visitor** — `StrictFiltersValidator` uses Fluid's `AstVisitor` pattern to walk the template AST and detect unknown filters
- **Decorator pattern** — `ValidatingTemplateCache` decorates Fluid's template cache to enforce strict filter validation on included templates
- **PS → Fluid model conversion** — `PsModelConverter` recursively converts Hashtables, PSCustomObjects, and collections into Fluid-compatible dictionaries

### Dependencies

| Package | Version | Role |
|---------|---------|------|
| [Fluid.Core](https://github.com/sebastienros/fluid) | 2.31.0 | Liquid template engine |
| PowerShellStandard.Library | 5.1.1 | PowerShell Standard API |
| System.Management.Automation | 7.4.0 | PowerShell 7.4 API |
| Microsoft.Extensions.FileProviders.Physical | 8.0.0 | File system provider for includes |

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

## License

[Apache License 2.0](LICENSE)
