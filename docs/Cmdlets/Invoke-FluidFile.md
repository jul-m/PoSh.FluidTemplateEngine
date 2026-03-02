# Invoke-FluidFile

## SYNOPSIS

Renders a Liquid template from a file.

## SYNTAX

```pwsh
# 'Default' ParameterSet:
Invoke-FluidFile [-Path] <string> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'HtmlEncoded' ParameterSet:
Invoke-FluidFile [-Path] <string> -HtmlEncode <SwitchParameter> -Model <object> [-TemplateRoot <string>] [<CommonParameters>]

# 'NoEncoding' ParameterSet:
Invoke-FluidFile [-Path] <string> -Model <object> -NoEncoding <SwitchParameter> [-TemplateRoot <string>] [<CommonParameters>]
```

## DESCRIPTION

By default, -TemplateRoot is deduced from the file's folder (useful for {% include %}).

## PARAMETERS

### `-Path <string>`
Path to the template file to render.
- ParameterSet: **All**
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **Yes, ByValue and ByPropertyName**
- Aliases: `FullName`
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

### Example 1: Render a .liquid file

```pwsh
Invoke-FluidFile -Path './templates/main.liquid' -Model @{ value = 'X' }
```

### Example 2: Render with an explicit include root

```pwsh
Invoke-FluidFile -Path './templates/main.liquid' -TemplateRoot './templates' -Model @{ value = 'X' }
```

