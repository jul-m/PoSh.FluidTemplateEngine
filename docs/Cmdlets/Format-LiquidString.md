# Format-LiquidString

## SYNOPSIS

Parses and renders a Liquid template (in one step).

## SYNTAX

```pwsh
# 'Default' ParameterSet:
Format-LiquidString [-Source] <string> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'HtmlEncoded' ParameterSet:
Format-LiquidString [-Source] <string> -HtmlEncode <SwitchParameter> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'NoEncoding' ParameterSet:
Format-LiquidString [-Source] <string> -Model <object> -NoEncoding <SwitchParameter> [-TemplateRoot <string>] [<CommonParameters>]
```

## DESCRIPTION

This cmdlet parses then renders a Liquid template via Fluid.

By default, the output is not encoded. Use -HtmlEncode to enable HTML encoding.

## PARAMETERS

### `-Source <string>`
The source code of the Liquid template.
- ParameterSet: **All**
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
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

### Example 1: Render a Liquid string

```pwsh
Format-LiquidString -Source 'Hello {{ name }}' -Model @{ name = 'Alice' }
```

### Example 2: Enable HTML encoding

```pwsh
Format-LiquidString -Source '{{ value }}' -Model @{ value = '<tag>' } -HtmlEncode
```

