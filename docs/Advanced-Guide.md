# Advanced Guide — PoSh.FluidTemplateEngine

This guide covers advanced features of the module beyond the standard cmdlet documentation.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Custom Tags](#custom-tags)
- [Custom Blocks](#custom-blocks)
- [Custom Operators](#custom-operators)
- [Custom Filters](#custom-filters)
- [Functions and Macros](#functions-and-macros)
- [Parentheses Grouping](#parentheses-grouping)
- [Whitespace Control](#whitespace-control)
- [Strict Modes](#strict-modes)
- [Includes and Partials](#includes-and-partials)
- [.NET Type Access](#net-type-access)
- [Localization](#localization)
- [JSON Options](#json-options)
- [Cache Management and Performance](#cache-management-and-performance)
- [Non-Standard Built-in Filters](#non-standard-built-in-filters)
- [Complete Liquid Syntax](#complete-liquid-syntax)
- [Patterns and Recipes](#patterns-and-recipes)

---

## Architecture Overview

### Engine Lifecycle

The module uses a **fingerprint-based caching** engine:

```
┌──────────────────────┐
│ Set-FluidModuleConfig│ ─── modifies ──→ $Global:FluidModuleConfiguration
│ Register-Liquid*     │ ─── modifies ──→ Static registries (FluidManager)
└──────────────────────┘
          │
          ▼ (next render call)
┌──────────────────────┐
│    FluidManager      │
│  ┌─────────────────┐ │
│  │ Compute         │ │  ← All config values + registrations
│  │ fingerprint     │ │
│  └────────┬────────┘ │
│           │          │
│  ┌────────▼────────┐ │
│  │ Fingerprint   ≠ │──── Rebuild: FluidParser + TemplateOptions
│  │ changed?     == │──── Reuse cache
│  └─────────────────┘ │
└──────────────────────┘
```

### Internal Components

| Component | Role |
|-----------|------|
| `FluidManager` | Static singleton. Caches the parser and options. Manages filter, tag, block, and operator registrations. |
| `PsModelConverter` | Recursively converts Hashtable / PSCustomObject / collections to Fluid dictionaries. |
| `StrictFiltersValidator` | AST visitor (`AstVisitor`) that walks the syntax tree to detect unknown filters. |
| `ValidatingTemplateCache` | Decorator of Fluid's template cache. Validates strict filters on included templates. |
| `ScriptBlockBinaryExpression` | Binary expression that delegates custom operator evaluation to a PowerShell ScriptBlock. |
| `FluidModuleConfiguration` | Configuration object persisted in a PS global variable (`$Global:FluidModuleConfiguration`). |

---

## Custom Tags

Tags are **self-closing** Liquid elements (no `{% end... %}`). They are registered via `Register-LiquidTag`.

### Tag Types

| Type | Parameter | Liquid Example | ScriptBlock Receives |
|------|-----------|----------------|----------------------|
| `Empty` | None | `{% timestamp %}` | Nothing |
| `Identifier` | An identifier | `{% hello world %}` | `param($identifier)` |
| `Expression` | An evaluated expression | `{% echo 'text' \| upcase %}` | `param($value)` |

### Empty Tag — No Parameter

The ScriptBlock receives no arguments. It returns the text to write.

```powershell
Register-LiquidTag -Name 'timestamp' -Type Empty -ScriptBlock {
    (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

Register-LiquidTag -Name 'hostname' -Type Empty -ScriptBlock {
    [System.Net.Dns]::GetHostName()
}
```

```liquid
Generated on {% timestamp %} from {% hostname %}
```

### Identifier Tag — With Identifier

The ScriptBlock receives the identifier (raw text) as its first argument.

```powershell
Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
    param($identifier)
    "Hello $identifier!"
}

Register-LiquidTag -Name 'env' -Type Identifier -ScriptBlock {
    param($identifier)
    [Environment]::GetEnvironmentVariable($identifier) ?? "[env:$identifier not set]"
}
```

```liquid
{% hello World %}
PATH = {% env PATH %}
```

### Expression Tag — With Evaluated Expression

The ScriptBlock receives the **evaluated** value of the Liquid expression (filters applied).

```powershell
Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
    param($value)
    ">> $value <<"
}
```

```liquid
{% echo 'hello' | upcase %}       → >> HELLO <<
{% echo name %}                    → >> Alice << (if name='Alice')
{% echo 1 | plus: 2 | times: 3 %} → >> 9 <<
```

---

## Custom Blocks

Blocks are Liquid elements with **inner content** between `{% name %}` and `{% endname %}`. They are registered via `Register-LiquidBlock`.

### Block Types

| Type | Parameter | Liquid Example | ScriptBlock Receives |
|------|-----------|----------------|----------------------|
| `Empty` | None | `{% card %}...{% endcard %}` | `param($body)` |
| `Identifier` | An identifier | `{% tag div %}...{% endtag %}` | `param($identifier, $body)` |
| `Expression` | An evaluated expression | `{% repeat 3 %}...{% endrepeat %}` | `param($value, $body)` |

The **body** (`$body`) is the rendered content of the block (Liquid variables are already resolved).

### Empty Block — Content Wrapper

```powershell
Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
    param($body)
    "<div class='card'>$body</div>"
}

Register-LiquidBlock -Name 'uppercase' -Type Empty -ScriptBlock {
    param($body)
    $body.ToUpperInvariant()
}
```

```liquid
{% card %}
  <h2>{{ title }}</h2>
  <p>{{ description }}</p>
{% endcard %}

{% uppercase %}hello world{% enduppercase %}
```

### Identifier Block — Named Wrapper

```powershell
Register-LiquidBlock -Name 'tag' -Type Identifier -ScriptBlock {
    param($identifier, $body)
    "<$identifier>$body</$identifier>"
}

Register-LiquidBlock -Name 'wrapper' -Type Identifier -ScriptBlock {
    param($identifier, $body)
    "<div class='$identifier'>$body</div>"
}
```

```liquid
{% tag section %}
  Article content here
{% endtag %}

{% wrapper hero %}
  <h1>Welcome</h1>
{% endwrapper %}
```

### Expression Block — Parameterized Block

```powershell
# Repeat content N times
Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
    param($value, $body)
    $body * [int]$value
}

# Indent content
Register-LiquidBlock -Name 'indent' -Type Expression -ScriptBlock {
    param($value, $body)
    $prefix = ' ' * [int]$value
    ($body -split "`n" | ForEach-Object { "$prefix$_" }) -join "`n"
}
```

```liquid
{% repeat 3 %}Go! {% endrepeat %}
→ Go! Go! Go!

{% repeat items.size %}*{% endrepeat %}
→ *** (for 3 items)
```

---

## Custom Operators

Operators are used in `{% if %}` conditions to compare values. They are registered via `Register-LiquidOperator`.

The ScriptBlock receives `$left` and `$right` (the two evaluated operands) and must return a **boolean**.

### Examples

```powershell
# XOR operator
Register-LiquidOperator -Name 'xor' -ScriptBlock {
    param($left, $right)
    [bool]$left -xor [bool]$right
}

# Regex match operator
Register-LiquidOperator -Name 'matches' -ScriptBlock {
    param($left, $right)
    [string]$left -match [string]$right
}

# Same-type operator
Register-LiquidOperator -Name 'sametype' -ScriptBlock {
    param($left, $right)
    $left.GetType() -eq $right.GetType()
}
```

```liquid
{% if true xor false %}XOR is true{% endif %}

{% if email matches '@company\.com$' %}Internal{% else %}External{% endif %}
```

### Built-in Operators

For reference, here are the standard Liquid operators available without registration:

| Operator | Description |
|----------|-------------|
| `==` | Equality |
| `!=` | Inequality |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |
| `contains` | Contains (string or array) |
| `and` | Logical AND |
| `or` | Logical OR |

---

## Custom Filters

Filters are registered via `Register-LiquidFilter`. The ScriptBlock receives the input value as its first argument, followed by positional arguments.

### Simple Filter

```powershell
Register-LiquidFilter -Name 'shout' -ScriptBlock {
    param($input)
    $input.ToString().ToUpperInvariant()
}
```

```liquid
{{ "hello" | shout }} → HELLO
```

### Filter with Arguments

```powershell
Register-LiquidFilter -Name 'wrap' -ScriptBlock {
    param($input, $before, $after)
    "$before$input$after"
}
```

```liquid
{{ "world" | wrap: "Hello ", "!" }} → Hello world!
```

### Advanced Filter — Formatting

```powershell
Register-LiquidFilter -Name 'pad' -ScriptBlock {
    param($input, $width, $char)
    if (-not $char) { $char = ' ' }
    $input.ToString().PadRight([int]$width, [char]$char)
}
```

```liquid
{{ "Hi" | pad: 10, "." }} → Hi........
```

---

## Functions and Macros

Fluid supports functions and macros, an extension beyond standard Liquid.

### Enabling

```powershell
Set-FluidModuleConfig -AllowFunctions
```

### Defining a Macro (Template-Local)

Macros (`{% macro %}`) define reusable template fragments with named parameters and default values.

```powershell
Set-FluidModuleConfig -AllowFunctions

$source = @'
{% macro field(name, value='', type='text') %}
<div class="field">
  <input type="{{ type }}" name="{{ name }}" value="{{ value }}" />
</div>
{% endmacro %}

{{ field('user') }}
{{ field('pass', type='password') }}
{{ field('email', value='test@example.com', type='email') }}
'@

Format-LiquidString -Source $source -Model @{}
```

> **Important:** Macros must be defined **before** they are used in the template.

### Importing Macros from Another Template

```powershell
Set-FluidModuleConfig -AllowFunctions -TemplateRoot './templates'
```

```liquid
{# templates/forms.liquid #}
{% macro field(name, value='', type='text') %}
<input type="{{ type }}" name="{{ name }}" value="{{ value }}" />
{% endmacro %}
```

```liquid
{# main.liquid #}
{% from 'forms' import field %}

{{ field('user') }}
{{ field('pass', type='password') }}
```

### FunctionValue (via PowerShell)

Fluid functions are `FluidValue` objects that implement `InvokeAsync`. The module does not provide a dedicated cmdlet for this, but macros cover the majority of use cases.

---

## Parentheses Grouping

By default, Liquid operators are evaluated right-to-left and do not support parentheses. Enable optional support:

```powershell
Set-FluidModuleConfig -AllowParentheses
```

### Examples

```liquid
{{ 1 | plus: (2 | times: 3) }}  → 7  (instead of 9 without parentheses)
```

---

## Whitespace Control

### Hyphens in Templates

Use hyphens (`-`) in delimiters to strip whitespace:

| Syntax | Effect |
|--------|--------|
| `{%- ... %}` | Strip whitespace on the left |
| `{% ... -%}` | Strip whitespace on the right |
| `{%- ... -%}` | Strip both sides |
| `{{- ... }}` | Strip whitespace on the left (output) |
| `{{ ... -}}` | Strip whitespace on the right (output) |

### Automatic Trimming

Configure automatic trimming (without hyphens):

```powershell
# Common trimming configurations
Set-FluidModuleConfig -Trimming TagRight       # Strip right of tags
Set-FluidModuleConfig -Trimming TagBoth        # Strip both sides of tags
Set-FluidModuleConfig -Trimming All            # Strip everything
```

**Available flags (combinable):**

| Flag | Description |
|------|-------------|
| `None` | No automatic trimming |
| `TagLeft` | Whitespace to the left of tags (`{% %}`) |
| `TagRight` | Whitespace to the right of tags |
| `TagBoth` | = `TagLeft + TagRight` |
| `OutputLeft` | Whitespace to the left of outputs (`{{ }}`) |
| `OutputRight` | Whitespace to the right of outputs |
| `OutputBoth` | = `OutputLeft + OutputRight` |
| `All` | = `TagBoth + OutputBoth` |

### Greedy Mode

```powershell
# Greedy (default): removes ALL consecutive whitespace characters
Set-FluidModuleConfig -Greedy $true

# Non-greedy: removes only spaces before the first newline
Set-FluidModuleConfig -Greedy $false
```

---

## Strict Modes

### Strict Variables

Error on access to undefined variables:

```powershell
Set-FluidModuleConfig -StrictVariables
Format-LiquidString -Source '{{ missing }}' -Model @{} -ErrorAction Stop
# Error: Undefined variable 'missing'
```

### Undefined Format (Fallback)

When `StrictVariables` is disabled, provide a fallback format:

```powershell
Set-FluidModuleConfig -UndefinedFormat '[MISSING: {name}]'
Format-LiquidString -Source '{{ unknown }}' -Model @{}
# Output: [MISSING: unknown]
```

The `{name}` placeholder is replaced with the variable path.

### Strict Filters

Error when using an unregistered filter:

```powershell
Set-FluidModuleConfig -StrictFilters
```

This check uses an **AST visitor** (`StrictFiltersValidator`) that:
1. Walks the entire syntax tree of the template
2. Collects all filter names used
3. Verifies they exist in Fluid's filter collection

**Important:** Validation also applies to included templates via `{% include %}` / `{% render %}` thanks to the `ValidatingTemplateCache` (cache decorator).

---

## Includes and Partials

### Root Directory Configuration

```powershell
# Global configuration
Set-FluidModuleConfig -TemplateRoot './templates'

# Or per-call
Invoke-FluidFile -Path './templates/main.liquid' -TemplateRoot './templates'
Format-LiquidString -Source '{% include "header" %}' -TemplateRoot './templates'
```

### include vs render

| Tag | Scope | Description |
|-----|-------|-------------|
| `{% include 'partial' %}` | Shared | The partial accesses the parent context's variables |
| `{% render 'partial' %}` | Isolated | The partial has its own isolated context |

### Passing Variables

```liquid
{% include 'card' with product %}
{% include 'card', title: 'Hello', subtitle: 'World' %}
{% render 'item' for items as item %}
```

### Automatic TemplateRoot Resolution

When using `Invoke-FluidFile`, the `TemplateRoot` is automatically inferred from the file's parent directory if not explicitly specified.

---

## .NET Type Access

By default, Fluid only allows access to dictionary keys and `PSCustomObject` properties. To use native .NET objects:

### Register a Complete Type

```powershell
Register-FluidType -Type ([System.Version])
# All public properties become accessible
```

### Register Specific Members

```powershell
Register-FluidType -TypeName 'System.IO.FileInfo' -Member Name, Length, Extension
```

### By Type Name

```powershell
Register-FluidType -TypeName 'System.Diagnostics.Process' -Member Id, ProcessName, WorkingSet64
```

### Ignore Member Casing

```powershell
Set-FluidModuleConfig -IgnoreMemberCasing $true
# Allows {{ obj.name }} even if the property is Name
```

---

## Localization

### Culture

```powershell
Set-FluidModuleConfig -Culture 'fr-FR'

Format-LiquidString -Source '{{ 1234.56 }}' -Model @{}
# Output: 1234,56 (French decimal separator)

Format-LiquidString -Source "{{ 'now' | date: '%A %d %B %Y' }}" -Model @{}
# Output: vendredi 28 février 2026
```

### Time Zone

```powershell
Set-FluidModuleConfig -TimeZoneId 'Europe/Paris'        # macOS / Linux
Set-FluidModuleConfig -TimeZoneId 'Romance Standard Time' # Windows
```

---

## JSON Options

The built-in `json` filter serializes objects to JSON:

```powershell
# Indented JSON
Set-FluidModuleConfig -JsonIndented $true

# Relaxed escaping (no escaping of <, >, &, ', etc.)
Set-FluidModuleConfig -JsonRelaxedEscaping $true
```

```liquid
{{ data | json }}
```

---

## Cache Management and Performance

### How the Cache Works

The module uses a two-level caching system:

1. **Engine cache** (`FluidManager`) — The `FluidParser` and `TemplateOptions` are only recreated if the configuration changes (fingerprint comparison).
2. **Template cache** (`ITemplateCache`) — Templates included via `{% include %}`/`{% render %}` are parsed once and cached by Fluid.

### Performance Best Practices

1. **Pre-compile reused templates**:
```powershell
$tpl = New-FluidTemplate -Source $templateSource
# Reuse $tpl for each render
foreach ($item in $data) {
    $tpl | Invoke-FluidTemplate -Model @{ item = $item }
}
```

2. **Configure once, render often**:
```powershell
Set-FluidModuleConfig -TemplateRoot './templates' -Culture 'fr-FR'
# All subsequent renders reuse the same engine
```

3. **Avoid changing configuration in a loop** — Each config change invalidates the engine cache.

### Execution Limits

```powershell
# Limit execution steps (prevents infinite loops)
Set-FluidModuleConfig -MaxSteps 100000

# Limit recursion depth (nested includes)
Set-FluidModuleConfig -MaxRecursion 20
```

---

## Non-Standard Built-in Filters

In addition to the [standard Liquid filters](https://shopify.github.io/liquid/filters/), Fluid provides:

### `format_date`

Formats dates using .NET standard formats:

```liquid
{{ "now" | format_date: "G" }}        → 02/28/2026 14:30:00
{{ "now" | format_date: "yyyy-MM-dd" }} → 2026-02-28
```

[.NET date format documentation](https://docs.microsoft.com/dotnet/standard/base-types/standard-date-and-time-format-strings)

### `format_number`

Formats numbers using .NET standard formats:

```liquid
{{ 1234.5 | format_number: "N2" }} → 1,234.50
{{ 1234.5 | format_number: "C" }}  → $1,234.50
```

[.NET number format documentation](https://docs.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings)

### `format_string`

.NET composite format:

```liquid
{{ "hello {0} {1:C}" | format_string: "world", 123 }} → hello world $123.00
```

---

## Complete Liquid Syntax

Quick reference of the main supported Liquid constructs:

### Variables

```liquid
{{ variable }}
{{ object.property }}
{{ array[0] }}
{{ variable | filter }}
{{ variable | filter: arg1, arg2 }}
```

### Control Tags

```liquid
{% if condition %}...{% elsif other %}...{% else %}...{% endif %}
{% unless condition %}...{% endunless %}
{% case variable %}{% when value %}...{% else %}...{% endcase %}
```

### Loops

```liquid
{% for item in array %}
  {{ item }} — {{ forloop.index }} / {{ forloop.length }}
{% endfor %}

{% for i in (1..5) %}{{ i }}{% endfor %}

{% tablerow item in array cols:3 %}{{ item }}{% endtablerow %}
```

### Variable Assignment

```liquid
{% assign name = "value" %}
{% capture name %}...{% endcapture %}
{% increment counter %}
{% decrement counter %}
```

### Includes

```liquid
{% include 'partial' %}
{% include 'partial' with variable %}
{% render 'partial' for array as item %}
```

### Comments

```liquid
{% comment %}This is ignored{% endcomment %}
{# This is also a comment #}
```

### Raw Output

```liquid
{% raw %}{{ this is not parsed }}{% endraw %}
```

---

## Patterns and Recipes

### Markdown Generation

```powershell
$source = @'
# {{ title }}

{% for section in sections %}
## {{ section.heading }}

{{ section.content }}

{% endfor %}
'@

$model = @{
    title = 'Documentation'
    sections = @(
        @{ heading = 'Installation'; content = 'Run `Install-Module`...' }
        @{ heading = 'Usage'; content = 'Import the module...' }
    )
}

Format-LiquidString -Source $source -Model $model
```

### Template Composition with Includes

```powershell
# layout.liquid:
# <html><body>{% renderbody %}</body></html>

# page.liquid:
# {% layout 'layout' %}
# <h1>{{ title }}</h1>

# Note: layout/renderbody requires the Fluid View Engine (MVC).
# In the PS module, use {% include %} for template composition.
```

### Transformation Pipeline

```powershell
# Compile once, render for each item
$template = New-FluidTemplate -Source '| {{ name | pad_right: 20 }} | {{ value | pad_right: 10 }} |'

$data | ForEach-Object {
    $template | Invoke-FluidTemplate -Model $_
}
```

### Templates from Files with Dynamic Models

```powershell
$files = Get-ChildItem -Path './data' -Filter '*.json'

foreach ($file in $files) {
    $model = Get-Content $file.FullName | ConvertFrom-Json -AsHashtable
    Invoke-FluidFile -Path './templates/report.liquid' -Model $model
}
```

---

## Extension Approach Comparison

| Need | Solution | Cmdlet |
|------|----------|--------|
| Transform a value | Custom filter | `Register-LiquidFilter` |
| Inject content (no body) | Custom tag | `Register-LiquidTag` |
| Wrap/transform a content block | Custom block | `Register-LiquidBlock` |
| New comparison in `{% if %}` | Custom operator | `Register-LiquidOperator` |
| Reusable fragment (in-template) | Macro | `{% macro %}...{% endmacro %}` |
| .NET types in templates | Type registration | `Register-FluidType` |
