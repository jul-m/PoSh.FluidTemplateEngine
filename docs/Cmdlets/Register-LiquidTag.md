# Register-LiquidTag

## SYNOPSIS

Registers a custom Liquid tag (without closing block).

## SYNTAX

```pwsh
Register-LiquidTag [-Name] <string> [-Type] {Empty | Identifier | Expression} [-ScriptBlock] <ScriptBlock> 
[<CommonParameters>]
```

## DESCRIPTION

A tag is a Liquid element without internal content (no {%% end... %%}). The ScriptBlock returns the text to write in the rendering.

Three tag types are supported : Empty Tag with no parameter. ScriptBlock receives no argument. E.g.: {%% mytag %%} Identifier Tag with an identifier. ScriptBlock receives $identifier. E.g.: {%% hello world %%} Expression Tag with an evaluated expression. ScriptBlock receives $value. E.g.: {%% echo 'text' | upcase %%}

## PARAMETERS

### `-Name <string>`
Name of the tag (e.g. hello, timestamp).
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Type <PoSh.FluidTemplateEngine.Core.LiquidTagType>`
Type of tag parameter: Empty, Identifier, or Expression.
- Required: **Yes**
- Position: **1**
- Default value: **Empty**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-ScriptBlock <System.Management.Automation.ScriptBlock>`
Tag implementation as ScriptBlock.\§ The ScriptBlock must return the text to write.  
 - Empty: no argument  
 - Identifier: param($identifier)  
 - Expression: param($value) (evaluated expression)
- Required: **Yes**
- Position: **2**
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

### Example 1: Empty tag

```pwsh
Register-LiquidTag -Name 'timestamp' -Type Empty -ScriptBlock {
    (Get-Date).ToString('o')
}
```

### Example 2: Tag with identifier

```pwsh
Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
    param($identifier)
    "Hello $identifier!"
}
```

### Example 3: Tag with expression

```pwsh
Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
    param($value)
    "[$value]"
}
```

