# Register-LiquidBlock

## SYNOPSIS

Registers a custom Liquid block (with closing block).

## SYNTAX

```pwsh
Register-LiquidBlock [-Name] <string> [-Type] {Empty | Identifier | Expression} [-ScriptBlock] <ScriptBlock> 
[<CommonParameters>]
```

## DESCRIPTION

A block is a Liquid element with internal content delimited by {%% name %%}...{%% endname %%}. The ScriptBlock receives the rendered body content and returns the final text.

Three block types are supported : Empty Block with no parameter. ScriptBlock receives $body. E.g.: {%% wrap %%}...{%% endwrap %%} Identifier Block with an identifier. ScriptBlock receives $identifier and $body. E.g.: {%% tag div %%}...{%% endtag %%} Expression Block with an evaluated expression. ScriptBlock receives $value and $body. E.g.: {%% repeat 3 %%}...{%% endrepeat %%}

## PARAMETERS

### `-Name <string>`
Name of the block (e.g. repeat, card). The closing tag will be end<name>.
- Required: **Yes**
- Position: **0**
- Default value: *none*
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-Type <PoSh.FluidTemplateEngine.Core.LiquidTagType>`
Type of block parameter: Empty, Identifier, or Expression.
- Required: **Yes**
- Position: **1**
- Default value: **Empty**
- Accept pipeline input: **No**
- Aliases: *none*
- Accept wildcard characters: **No**

### `-ScriptBlock <System.Management.Automation.ScriptBlock>`
Block implementation as ScriptBlock.\§ The ScriptBlock receives the rendered content and must return the final text.  
 - Empty: param($body)  
 - Identifier: param($identifier, $body)  
 - Expression: param($value, $body) (evaluated expression)
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

### Example 1: Empty block: HTML wrapper

```pwsh
Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
    param($body)
    "<div class='card'>$body</div>"
}
```

### Example 2: Block with identifier: named wrapper

```pwsh
Register-LiquidBlock -Name 'tag' -Type Identifier -ScriptBlock {
    param($identifier, $body)
    "<$identifier>$body</$identifier>"
}
```

### Example 3: Block with expression: repeat the content N times

```pwsh
Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
    param($value, $body)
    $body * [int]$value
}
```

