# Configuration Reference — PoSh.FluidTemplateEngine

The complete reference for using the module: every `Set-FluidModuleConfig` option, and how to use every core feature — custom filters, tags, blocks, operators, macros, whitespace control, strict modes, includes, and .NET type access.

> For internals (architecture, caching), the full Liquid syntax cheat sheet, and patterns/recipes, see the [Advanced Guide](Advanced-Guide.md).

---

## Table of Contents

- [Basic Usage](#basic-usage)
- [Viewing & Resetting Configuration](#viewing--resetting-configuration)
- [All Configuration Options](#all-configuration-options)
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

---

## Basic Usage

### One-Shot Rendering

`Format-LiquidString` parses and renders a template in a single call — the simplest way to render a one-off template:

```powershell
Format-LiquidString -Source 'Hello {{ name }}!' -Model @{ name = 'Alice' }
# Output: Hello Alice!
```

### Compile + Render (Recommended for Repeated Use)

`New-FluidTemplate` compiles a template once into a reusable object; pipe it into `Invoke-FluidTemplate` for each render, avoiding re-parsing the same source on every call:

```powershell
$template = New-FluidTemplate -Source 'Hi {{ name }}, welcome!'
$template | Invoke-FluidTemplate -Model @{ name = 'Bob' }
# Output: Hi Bob, welcome!
```

### Render from File with Includes

`Invoke-FluidFile` renders a template stored on disk. Set `-TemplateRoot` (globally via `Set-FluidModuleConfig`, or per-call) so `{% include %}` / `{% render %}` can resolve partials:

```powershell
Set-FluidModuleConfig -TemplateRoot './templates'
Invoke-FluidFile -Path './templates/main.liquid' -Model @{ title = 'Home' }
```

### Complex Data Models

Any combination of hashtables, arrays, and `PSCustomObject`s works as a model:

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

## Viewing & Resetting Configuration

```powershell
# View current configuration
Get-FluidModuleConfig

# Reset to defaults
Set-FluidModuleConfig -Reset
```

Configuration is stored in `$Global:FluidModuleConfiguration` for the current session. The underlying Fluid engine is rebuilt automatically the next time it's needed whenever a configuration value changes — see [Architecture Overview](Advanced-Guide.md#architecture-overview) for how the fingerprint-based cache works.

---

## All Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-TemplateRoot` | `string` | `$PWD` | Root directory for `{% include %}` / `{% render %}` — see [Include & Render](#include--render) |
| `-StrictVariables` | `switch` | `$false` | Error on undefined variables — see [Strict Modes](#strict-modes) |
| `-StrictFilters` | `switch` | `$false` | Error on unknown filters (including in includes) — see [Strict Modes](#strict-modes) |
| `-UndefinedFormat` | `string` | `$null` | Fallback format for undefined variables (e.g. `[{name} not found]`) — see [Strict Modes](#strict-modes) |
| `-MaxSteps` | `int` | `0` | Maximum execution steps (0 = unlimited) — see [Execution Limits](#execution-limits) |
| `-MaxRecursion` | `int` | `$null` | Maximum recursion depth for includes/renders — see [Execution Limits](#execution-limits) |
| `-AllowFunctions` | `switch` | `$false` | Enable function/macro syntax — see [Functions & Macros](#functions--macros) |
| `-AllowParentheses` | `switch` | `$false` | Enable expression grouping with parentheses — see [Expression Grouping](#expression-grouping-parentheses) |
| `-Culture` | `string` | `$null` | Culture for date/number formatting (e.g. `fr-FR`) — see [Localization](#localization) |
| `-TimeZoneId` | `string` | `$null` | Time zone for date parsing (e.g. `Europe/Paris`) — see [Time Zones](#time-zones) |
| `-Trimming` | `TrimmingFlags` | `None` | Automatic whitespace trimming rules — see [Whitespace Control](#whitespace-control) |
| `-Greedy` | `bool` | `$true` | When true, trimming removes all successive blank chars — see [Whitespace Control](#whitespace-control) |
| `-ModelNamesComparer` | `enum` | `OrdinalIgnoreCase` | How property names are compared — see [Model Names Comparison](#model-names-comparison) |
| `-IgnoreMemberCasing` | `bool` | `$false` | Ignore case for CLR member access — see [Type Registration (CLR Access)](#type-registration-clr-access) |
| `-JsonIndented` | `bool` | `$false` | Indented output for the `json` filter — see [JSON Options](#json-options) |
| `-JsonRelaxedEscaping` | `bool` | `$false` | Relaxed JSON escaping (`UnsafeRelaxedJsonEscaping`) — see [JSON Options](#json-options) |

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

> More tag examples and the full type comparison table are in the [Advanced Guide](Advanced-Guide.md#custom-tags).

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

> More block examples and the full type comparison table are in the [Advanced Guide](Advanced-Guide.md#custom-blocks).

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

> Built-in Liquid operators (`==`, `contains`, `and`, `or`, ...) that don't require registration are listed in the [Advanced Guide](Advanced-Guide.md#built-in-operators).

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

> **Important:** Macros must be defined **before** they are used in the template.

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

`-HtmlEncode` is a per-call switch on `Format-LiquidString` / `Invoke-FluidTemplate` / `Invoke-FluidFile`, not a `Set-FluidModuleConfig` option — enable it on every call where the output is embedded in HTML.

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

> The template root is automatically inferred from the file's directory when using `Invoke-FluidFile`, unless explicitly overridden. `include` vs `render` scoping and variable-passing syntax are covered in the [Advanced Guide](Advanced-Guide.md#includes-and-partials).

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

Controls how PowerShell object property names (hashtable keys, `PSCustomObject` properties) are matched against variable names used in templates.

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

## See Also

- [Advanced Guide](Advanced-Guide.md) — architecture, caching internals, the full Liquid syntax cheat sheet, and patterns & recipes
- [`Set-FluidModuleConfig` cmdlet reference](Cmdlets/Set-FluidModuleConfig.md)
- [`Get-FluidModuleConfig` cmdlet reference](Cmdlets/Get-FluidModuleConfig.md)
