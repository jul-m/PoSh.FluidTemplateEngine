# PoSh.FluidTemplateEngine

[![CI](https://github.com/jul-m/PoSh.FluidTemplateEngine/actions/workflows/ci.yml/badge.svg)](https://github.com/jul-m/PoSh.FluidTemplateEngine/actions/workflows/ci.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PoSh.FluidTemplateEngine?style=flat-square&label=PSGallery)](https://www.powershellgallery.com/packages/PoSh.FluidTemplateEngine)
[![PowerShell 7.0+](https://img.shields.io/badge/PowerShell-7.0+-blue?style=flat-square)](https://github.com/PowerShell/PowerShell)
[![.NET 8.0+](https://img.shields.io/badge/.NET-8.0+-512bd4?style=flat-square)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green?style=flat-square)](LICENSE)

A **PowerShell module** for rendering [**Liquid**](https://shopify.github.io/liquid/) templates, powered by the high-performance [**Fluid**](https://github.com/sebastienros/fluid) .NET engine.

Render from strings or files, extend Liquid with PowerShell-backed filters, tags, blocks and operators, and enforce strict variable/filter checking — all as native PowerShell cmdlets.

> 📘 **[Configuration Reference](docs/Configuration-Reference.md)** — the complete guide to every feature: all `Set-FluidModuleConfig` options, custom filters/tags/blocks/operators, macros, strict modes, whitespace control, includes, and .NET type access.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Cmdlets](#core-cmdlets)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## Features

| Feature | Description |
|---------|-------------|
| **Liquid Rendering** | Full Liquid syntax — variables, filters, tags, loops, conditionals, whitespace control |
| **Compiled Templates** | Parse once, render many times; the engine itself is cached and reused across calls |
| **File-Based Rendering** | Render templates from disk, with `{% include %}` / `{% render %}` partial support |
| **Custom Extensions** | Register PowerShell ScriptBlocks as Liquid filters, tags, blocks and operators |
| **Functions & Macros** | `{% macro %}` definitions and `{{ func() }}` call syntax, importable across files |
| **Strict Modes** | Strict variables and strict filters, enforced through includes as well |
| **CLR Type Access** | Allow-list .NET types and members for safe object access inside templates |
| **Localization** | Per-render or global culture and time zone for dates and numbers |
| **HTML Encoding** | Optional output encoding to guard against injection |

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

### 4. Register a Custom Filter

```powershell
Register-LiquidFilter -Name 'shout' -ScriptBlock {
    param($input)
    $input.ToString().ToUpperInvariant()
}

Format-LiquidString -Source '{{ name | shout }}' -Model @{ name = 'hello' }
# Output: HELLO
```

> For macros, custom tags/blocks/operators, strict modes, and every other feature, see the [Configuration Reference](docs/Configuration-Reference.md) — or the [Advanced Guide](docs/Advanced-Guide.md) for architecture, internals, and patterns & recipes. Runnable scripts are also available in [`examples/`](examples/).

---

## Core Cmdlets

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

---

## Documentation

| Resource | Description |
|----------|-------------|
| ⭐ [Configuration Reference](docs/Configuration-Reference.md) | **Start here.** Every `Set-FluidModuleConfig` option, custom filters/tags/blocks/operators, macros, whitespace control, strict modes, includes, encoding, and .NET type access |
| [Cmdlet Reference](docs/README.md) | Full auto-generated reference for every cmdlet |
| [Advanced Guide](docs/Advanced-Guide.md) | Architecture, caching internals, the full Liquid syntax cheat sheet, and patterns & recipes |
| [Examples](examples/) | Runnable example scripts |
| [Contributing Guide](CONTRIBUTING.md) | Build, test, coding conventions, and how to submit changes |

---

## Contributing

Contributions are welcome! Please read the [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.

## License

[Apache License 2.0](LICENSE)
