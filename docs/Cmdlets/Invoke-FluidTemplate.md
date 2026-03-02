# Invoke-FluidTemplate

## SYNOPSIS

Renders a compiled Liquid template with a model.

## SYNTAX

```pwsh
# 'Default' ParameterSet:
Invoke-FluidTemplate [-Template] <object> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'HtmlEncoded' ParameterSet:
Invoke-FluidTemplate [-Template] <object> -HtmlEncode <SwitchParameter> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'NoEncoding' ParameterSet:
Invoke-FluidTemplate [-Template] <object> -Model <object> -NoEncoding <SwitchParameter> [-TemplateRoot <string>] [<CommonParameters>]
```

## DESCRIPTION

Accepts as input a template from New-FluidTemplate (pipeline) or a Fluid IFluidTemplate instance.

## PARAMETERS

### `-Template <object>`
The compiled template (or an IFluidTemplate).
- ParameterSet: **All**
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **Yes, ByValue**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Model <object>`
The model (hashtable, PSCustomObject, or object) exposed to the template.
- ParameterSet: **All**
- Required: **Yes**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-HtmlEncode <SwitchParameter>`
Enables HTML encoding (HtmlEncoder.Default) during rendering.
- ParameterSet: `HtmlEncoded`
- Required: **Yes** (for ParameterSet: `HtmlEncoded`)
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-NoEncoding <SwitchParameter>`
Backward compatibility with old PowerShell wrapper. Has no effect as encoding is disabled by default.
- ParameterSet: `NoEncoding`
- Required: **Yes** (for ParameterSet: `NoEncoding`)
- Position: **named**
- Default value: **False**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-TemplateRoot <string>`
Root directory for templates for include/render tags.
- ParameterSet: **All**
- Required: **Not Required**
- Position: **named**
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
[String]
```

## EXAMPLES

### Example 1: Render a compiled template

```pwsh
New-FluidTemplate -Source 'Hi {{ name }}' | Invoke-FluidTemplate -Model @{ name = 'Bob' }
```

### Example 2: Rendering with HTML encoding

```pwsh
New-FluidTemplate -Source '{{ value }}' |
    Invoke-FluidTemplate -Model @{ value = '<tag>' } -HtmlEncode
```

