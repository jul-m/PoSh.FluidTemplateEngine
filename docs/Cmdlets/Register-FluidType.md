# Register-FluidType

## SYNOPSIS

Allow-lists a .NET type for property access in templates.

## SYNTAX

```pwsh
# 'ByType' ParameterSet:
Register-FluidType [-Type] <Type> [-Member <string[]>] [<CommonParameters>]

# 'ByName' ParameterSet:
Register-FluidType [-TypeName] <string> [-Member <string[]>] [<CommonParameters>]
```

## DESCRIPTION

Fluid is secure by default and only allows access to CLR members for registered types. This cmdlet registers a type in the member access strategy (TemplateOptions.MemberAccessStrategy).

## PARAMETERS

### `-Type <System.Type>`
.NET type to register (e.g. [MyType]).
- ParameterSet: `ByType`
- Required: **Yes** (for ParameterSet: `ByType`)
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-TypeName <string>`
Name of the .NET type to register (e.g. System.Version).
- ParameterSet: `ByName`
- Required: **Yes** (for ParameterSet: `ByName`)
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Member <string[]>`
List of allowed properties. If omitted, all public properties are registered.
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

```

## EXAMPLES

### Example 1: Register all public properties of a type

```pwsh
Register-FluidType -Type ([System.Diagnostics.Process])
```

### Example 2: Register only some properties

```pwsh
Register-FluidType -TypeName 'System.Diagnostics.Process' -Member Id, ProcessName
```

### Example 3: Render a CLR object directly after registration

```pwsh
Register-FluidType -TypeName 'System.Version' -Member Major, Minor
            Format-LiquidString -Source '{{ v.Major }}.{{ v.Minor }}' -Model @{ v = [Version]'1.2.3' }
```

