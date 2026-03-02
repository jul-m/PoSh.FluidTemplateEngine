# Get-FluidModuleConfig

## SYNOPSIS

Displays the global configuration of the PoSh.FluidTemplateEngine module.

## SYNTAX

```pwsh
Get-FluidModuleConfig [<CommonParameters>]
```

## DESCRIPTION

The configuration is stored in the current PowerShell session and is used by default by other cmdlets.

## PARAMETERS

### CommonParameters
> This cmdlet supports the common parameters: `Verbose`, `Debug`, `ErrorAction`,
>  `ErrorVariable`, `WarningAction`, `WarningVariable`, `InformationAction`, 
> `InformationVariable`, `OutAction`, `OutVariable`, `PipelineVariable`, and `OutBuffer`. 
> For more information, see *[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216)*.

## OUTPUTS

```pwsh
[PoSh.FluidTemplateEngine.Core.FluidModuleConfiguration]
```

## EXAMPLES

### Example 1: Display the current configuration

```pwsh
Get-FluidModuleConfig
```

