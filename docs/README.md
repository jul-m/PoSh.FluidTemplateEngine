# PoSh.FluidTemplateEngine Cmdlets

Complete reference of available cmdlets in the `PoSh.FluidTemplateEngine` module.

## Overview

Total cmdlets: **11**

## Cmdlets Reference
| Cmdlet | Synopsis |
|--------|----------|
| [Format-LiquidString](./Cmdlets/Format-LiquidString.md) | Parses and renders a Liquid template (in one step). |
| [Get-FluidModuleConfig](./Cmdlets/Get-FluidModuleConfig.md) | Displays the global configuration of the PoSh.FluidTemplateEngine module. |
| [Invoke-FluidFile](./Cmdlets/Invoke-FluidFile.md) | Renders a Liquid template from a file. |
| [Invoke-FluidTemplate](./Cmdlets/Invoke-FluidTemplate.md) | Renders a compiled Liquid template with a model. |
| [New-FluidTemplate](./Cmdlets/New-FluidTemplate.md) | Compiles a Liquid template into a reusable template. |
| [Register-FluidType](./Cmdlets/Register-FluidType.md) | Allow-lists a .NET type for property access in templates. |
| [Register-LiquidBlock](./Cmdlets/Register-LiquidBlock.md) | Registers a custom Liquid block (with closing block). |
| [Register-LiquidFilter](./Cmdlets/Register-LiquidFilter.md) | Registers a custom Liquid filter (ScriptBlock). |
| [Register-LiquidOperator](./Cmdlets/Register-LiquidOperator.md) | Registers a custom Liquid binary operator. |
| [Register-LiquidTag](./Cmdlets/Register-LiquidTag.md) | Registers a custom Liquid tag (without closing block). |
| [Set-FluidModuleConfig](./Cmdlets/Set-FluidModuleConfig.md) | Configures the global configuration of the PoSh.FluidTemplateEngine module. |

## Installation

To install the `PoSh.FluidTemplateEngine` module from the PowerShell Gallery, run:

```powershell
Install-Module -Name PoSh.FluidTemplateEngine
```

## Getting Help

For detailed information about any cmdlet from your terminal, use:

```powershell
Get-Help <cmdlet-name>
Get-Help <cmdlet-name> -Full
Get-Help <cmdlet-name> -Examples
```

## Module Information

- **Module Name**:[PoSh.FluidTemplateEngine](https://github.com/jul-m/PoSh.FluidTemplateEngine)- **Version**: `2.31.0`
- **Author**: jul-m

