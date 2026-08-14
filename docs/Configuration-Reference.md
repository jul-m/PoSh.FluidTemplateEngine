# Configuration Reference — PoSh.FluidTemplateEngine

Exhaustive reference for every module-wide option exposed via `Set-FluidModuleConfig`, plus the per-call output encoding switch. For narrative walk-throughs of what these options enable, see the [Advanced Guide](Advanced-Guide.md).

---

## Table of Contents

- [Viewing & Resetting Configuration](#viewing--resetting-configuration)
- [All Configuration Options](#all-configuration-options)
- [Encoding](#encoding)
- [Model Names Comparison](#model-names-comparison)

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
| `-TemplateRoot` | `string` | `$PWD` | Root directory for `{% include %}` / `{% render %}` — see [Includes and Partials](Advanced-Guide.md#includes-and-partials) |
| `-StrictVariables` | `switch` | `$false` | Error on undefined variables — see [Strict Modes](Advanced-Guide.md#strict-modes) |
| `-StrictFilters` | `switch` | `$false` | Error on unknown filters (including in includes) — see [Strict Modes](Advanced-Guide.md#strict-modes) |
| `-UndefinedFormat` | `string` | `$null` | Fallback format for undefined variables (e.g. `[{name} not found]`) — see [Strict Modes](Advanced-Guide.md#strict-modes) |
| `-MaxSteps` | `int` | `0` | Maximum execution steps (0 = unlimited) — see [Execution Limits](Advanced-Guide.md#execution-limits) |
| `-MaxRecursion` | `int` | `$null` | Maximum recursion depth for includes/renders — see [Execution Limits](Advanced-Guide.md#execution-limits) |
| `-AllowFunctions` | `switch` | `$false` | Enable function/macro syntax — see [Functions and Macros](Advanced-Guide.md#functions-and-macros) |
| `-AllowParentheses` | `switch` | `$false` | Enable expression grouping with parentheses — see [Parentheses Grouping](Advanced-Guide.md#parentheses-grouping) |
| `-Culture` | `string` | `$null` | Culture for date/number formatting (e.g. `fr-FR`) — see [Localization](Advanced-Guide.md#localization) |
| `-TimeZoneId` | `string` | `$null` | Time zone for date parsing (e.g. `Europe/Paris`) — see [Localization](Advanced-Guide.md#localization) |
| `-Trimming` | `TrimmingFlags` | `None` | Automatic whitespace trimming rules — see [Whitespace Control](Advanced-Guide.md#whitespace-control) |
| `-Greedy` | `bool` | `$true` | When true, trimming removes all successive blank chars — see [Whitespace Control](Advanced-Guide.md#whitespace-control) |
| `-ModelNamesComparer` | `enum` | `OrdinalIgnoreCase` | How property names are compared — see [Model Names Comparison](#model-names-comparison) |
| `-IgnoreMemberCasing` | `bool` | `$false` | Ignore case for CLR member access — see [.NET Type Access](Advanced-Guide.md#net-type-access) |
| `-JsonIndented` | `bool` | `$false` | Indented output for the `json` filter — see [JSON Options](Advanced-Guide.md#json-options) |
| `-JsonRelaxedEscaping` | `bool` | `$false` | Relaxed JSON escaping (`UnsafeRelaxedJsonEscaping`) — see [JSON Options](Advanced-Guide.md#json-options) |

---

## Encoding

By default, rendered output is **not encoded**. Pass `-HtmlEncode` to `Format-LiquidString` or `Invoke-FluidTemplate` / `Invoke-FluidFile` to HTML-encode the result:

```powershell
# No encoding (default)
Format-LiquidString -Source '{{ val }}' -Model @{ val = '<script>alert(1)</script>' }
# Output: <script>alert(1)</script>

# HTML encoded
Format-LiquidString -Source '{{ val }}' -Model @{ val = '<script>alert(1)</script>' } -HtmlEncode
# Output: &lt;script&gt;alert(1)&lt;/script&gt;
```

`-HtmlEncode` is a per-call switch, not a `Set-FluidModuleConfig` option — enable it on every call where the output is embedded in HTML.

---

## Model Names Comparison

Controls how PowerShell object property names (hashtable keys, `PSCustomObject` properties) are matched against variable names used in templates.

```powershell
# Case-sensitive property names
Set-FluidModuleConfig -ModelNamesComparer Ordinal
```

**Available modes:** `OrdinalIgnoreCase` (default), `Ordinal`, `InvariantCultureIgnoreCase`, `InvariantCulture`, `CurrentCultureIgnoreCase`, `CurrentCulture`

---

## See Also

- [Advanced Guide](Advanced-Guide.md) — custom extensions, architecture, and patterns
- [`Set-FluidModuleConfig` cmdlet reference](Cmdlets/Set-FluidModuleConfig.md)
- [`Get-FluidModuleConfig` cmdlet reference](Cmdlets/Get-FluidModuleConfig.md)
