# Register-LiquidOperator

## SYNOPSIS

Registers a custom Liquid binary operator.

## SYNTAX

```pwsh
Register-LiquidOperator [-Name] <string> [-ScriptBlock] <ScriptBlock> [<CommonParameters>]
```

## DESCRIPTION

Operators are used in Liquid conditions to compare values (e.g.: ==, contains). The ScriptBlock receives the two operands and must return a boolean.

## PARAMETERS

### `-Name <string>`
Operator keyword (e.g. xor, matches).
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-ScriptBlock <System.Management.Automation.ScriptBlock>`
Comparison implementation as ScriptBlock.\§ The ScriptBlock receives param($left, $right) and must return a boolean.
- Required: **Yes**
- Position: **1**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### CommonParameters
> This cmdlet supports the common parameters: `Verbose`, `Debug`, `ErrorAction`,
>  `ErrorVariable`, `WarningAction`, `WarningVariable`, `InformationAction`, 
> `InformationVariable`, `OutAction`, `OutVariable`, `PipelineVariable`, and `OutBuffer`. 
> For more information, see *[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216)*.

## OUTPUTS

```pwsh

```

## EXAMPLES

### Example 1: Custom XOR operator

```pwsh
Register-LiquidOperator -Name 'xor' -ScriptBlock { param($left, $right) [bool]$left -xor [bool]$right }
            Format-LiquidString -Source "{% if true xor false %}Yes{% endif %}" -Model @{}
```

### Example 2: Custom "matches" operator (regex)

```pwsh
Register-LiquidOperator -Name 'matches' -ScriptBlock { param($left, $right) $left -match $right }
            Format-LiquidString -Source "{% if name matches '^A' %}Starts with A{% endif %}" -Model @{ name = 'Alice' }
```

