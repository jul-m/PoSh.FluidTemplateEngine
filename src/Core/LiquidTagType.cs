namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// Determines the parameter style of a custom Liquid tag or block.
/// </summary>
public enum LiquidTagType
{
    /// <summary>Tag/block with no parameter (e.g. <c>{%% mytag %%}</c>).</summary>
    Empty,

    /// <summary>Tag/block taking an identifier as parameter (e.g. <c>{%% mytag myvar %%}</c>).</summary>
    Identifier,

    /// <summary>Tag/block taking an expression as parameter (e.g. <c>{%% mytag 'value' | upcase %%}</c>).</summary>
    Expression,
}
