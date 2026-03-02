# Set-FluidModuleConfig

## SYNOPSIS

Configures the global configuration of the PoSh.FluidTemplateEngine module.

## SYNTAX

```pwsh
Set-FluidModuleConfig [-AllowFunctions <SwitchParameter>] [-AllowParentheses <SwitchParameter>] [-Culture <string>] 
[-Greedy <bool>] [-IgnoreMemberCasing <bool>] [-JsonIndented <bool>] [-JsonRelaxedEscaping <bool>] [-MaxRecursion 
<int>] [-MaxSteps <int>] [-ModelNamesComparer {OrdinalIgnoreCase | Ordinal | InvariantCultureIgnoreCase | 
InvariantCulture | CurrentCultureIgnoreCase | CurrentCulture}] [-Reset <SwitchParameter>] [-StrictFilters 
<SwitchParameter>] [-StrictVariables <SwitchParameter>] [-TemplateRoot <string>] [-TimeZoneId <string>] [-Trimming 
{None | TagLeft | TagRight | OutputLeft | OutputRight}] [-UndefinedFormat <string>] [<CommonParameters>]
```

## DESCRIPTION

These options influence parsing/rendering (includes, strict modes, execution limits, etc.).

## PARAMETERS

### `-TemplateRoot <string>`
Root directory for templates for include/render tags.
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-StrictVariables <SwitchParameter>`
Enables strict mode: access to an unknown variable fails.
- Required: **Not Required**
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-StrictFilters <SwitchParameter>`
Enables strict mode: use of an unknown filter fails.
- Required: **Not Required**
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-MaxSteps <int>`
Maximum number of execution steps of a template (0 = unlimited).
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-MaxRecursion <int>`
Max recursion depth (includes/renders) (null = Fluid default).
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-AllowFunctions <SwitchParameter>`
Allows functions (FluidParserOptions.AllowFunctions) during parsing.
- Required: **Not Required**
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-AllowParentheses <SwitchParameter>`
Allows parentheses (FluidParserOptions.AllowParentheses) during parsing.
- Required: **Not Required**
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-UndefinedFormat <string>`
Fallback value when a variable is undefined (if -StrictVariables is disabled). Use the placeholder {name} to include the path. Example: [{name} not found]
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Culture <string>`
Culture used for rendering (e.g.: "fr-FR", "en-US").
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-TimeZoneId <string>`
System time zone used to parse dates without an explicit time zone (e.g.: "Europe/Paris").
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: `TimeZone`
- Accept wildcard characters: **No**

### `-Trimming <Fluid.TrimmingFlags>`
Default trimming rules (Fluid TemplateOptions.Trimming).
- Required: **Not Required**
- Position: **named**
- Default value: **None**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Greedy <bool>`
Enables/disables greedy mode for trimming (default: true).
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-ModelNamesComparer <PoSh.FluidTemplateEngine.Core.ModelNamesComparerMode>`
Comparer used for property names (ModelNamesComparer).
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-IgnoreMemberCasing <bool>`
Ignores casing when accessing members on registered .NET types.
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-JsonIndented <bool>`
Enables/disables indented JSON for the json filter.
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-JsonRelaxedEscaping <bool>`
Enables/disables relaxed JSON encoding (UnsafeRelaxedJsonEscaping) for the json filter.
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Reset <SwitchParameter>`
Resets the configuration to default values.
- Required: **Not Required**
- Position: **named**
- Default value: **False**
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

### Example 1: Set a root for includes

```pwsh
Set-FluidModuleConfig -TemplateRoot './templates'
```

### Example 2: Enable strict modes

```pwsh
Set-FluidModuleConfig -StrictVariables -StrictFilters
```

### Example 3: Limit execution

```pwsh
Set-FluidModuleConfig -MaxSteps 100000 -MaxRecursion 20
```

### Example 4: Reset

```pwsh
Set-FluidModuleConfig -Reset
```

