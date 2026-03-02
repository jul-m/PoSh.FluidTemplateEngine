# New-FluidTemplate

## SYNOPSIS

Compiles a Liquid template into a reusable template.

## SYNTAX

```pwsh
New-FluidTemplate [-Source] <string> [-Name <string>] [-TemplateRoot <string>] [<CommonParameters>]
```

## DESCRIPTION

The result can be passed to Invoke-FluidTemplate, including via the pipeline.

## PARAMETERS

### `-Source <string>`
The source code of the Liquid template.
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Name <string>`
Optional name (metadata) associated with the compiled template.
- Required: **Not Required**
- Position: **named**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-TemplateRoot <string>`
Root directory for templates for include/render tags.
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
[PoSh.FluidTemplateEngine.Core.CompiledFluidTemplate]
```

## EXAMPLES

### Example 1: Compile a template

```pwsh
$tpl = New-FluidTemplate -Source 'Hi {{ name }}'
```

### Example 2: Compile then render

```pwsh
New-FluidTemplate -Source 'Hi {{ name }}' | Invoke-FluidTemplate -Model @{ name = 'Bob' }
```

