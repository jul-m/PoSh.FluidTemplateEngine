# Register-LiquidFilter

## SYNOPSIS

Registers a custom Liquid filter (ScriptBlock).

## SYNTAX

```pwsh
Register-LiquidFilter [-Name] <string> [-ScriptBlock] <ScriptBlock> [<CommonParameters>]
```

## DESCRIPTION

The ScriptBlock receives as first argument the input value, then the positional arguments of the filter.

Liquid example: {{ name | shout }}

## PARAMETERS

### `-Name <string>`
Name of the filter (e.g. shout, prefix).
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-ScriptBlock <System.Management.Automation.ScriptBlock>`
Filter implementation as ScriptBlock.
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

### Example 1: Create a shout filter

```pwsh
Register-LiquidFilter -Name 'shout' -ScriptBlock { param($input) $input.ToString().ToUpperInvariant() }
```

### Example 2: Filter with arguments

```pwsh
Register-LiquidFilter -Name 'prefix' -ScriptBlock { param($input, $p) "$p$input" }
```

