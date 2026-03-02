using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Registers a custom Liquid block (with closing block).</summary>
/// <para>
/// A block is a Liquid element with internal content delimited by <c>{%% name %%}...{%% endname %%}</c>.
/// The ScriptBlock receives the rendered body content and returns the final text.
/// </para>
/// <para>
/// Three block types are supported :
/// <list type="bullet">
///   <item>
///     <term>Empty</term>
///     <description>
///       Block with no parameter. ScriptBlock receives <c>$body</c>.
///       E.g.: <c>{%% wrap %%}...{%% endwrap %%}</c>
///     </description>
///   </item>
///   <item>
///     <term>Identifier</term>
///     <description>
///       Block with an identifier. ScriptBlock receives <c>$identifier</c> and
///       <c>$body</c>. E.g.: <c>{%% tag div %%}...{%% endtag %%}</c>
///     </description>
///   </item>
///   <item>
///     <term>Expression</term>
///     <description>
///       Block with an evaluated expression. ScriptBlock receives <c>$value</c>
///       and <c>$body</c>. E.g.: <c>{%% repeat 3 %%}...{%% endrepeat %%}</c>
///     </description>
///   </item>
/// </list>
/// </para>
/// <example>
/// <summary>Empty block: HTML wrapper</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
///     param($body)
///     "&lt;div class='card'&gt;$body&lt;/div&gt;"
/// }
/// </code>
/// </example>
/// <example>
/// <summary>Block with identifier: named wrapper</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidBlock -Name 'tag' -Type Identifier -ScriptBlock {
///     param($identifier, $body)
///     "&lt;$identifier&gt;$body&lt;/$identifier&gt;"
/// }
/// </code>
/// </example>
/// <example>
/// <summary>Block with expression: repeat the content N times</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
///     param($value, $body)
///     $body * [int]$value
/// }
/// </code>
/// </example>
/// <seealso cref="RegisterLiquidTagCmdlet" />
/// <seealso cref="RegisterLiquidFilterCmdlet" />
[Cmdlet(VerbsLifecycle.Register, "LiquidBlock")]
public sealed class RegisterLiquidBlockCmdlet : PSCmdlet
{
    /// <summary>
    /// Name of the block (e.g. <c>repeat</c>, <c>card</c>). The closing tag will
    /// be <c>end&lt;name&gt;</c>.
    /// </summary>
    [Parameter(Mandatory = true, Position = 0)]
    public string? Name { get; set; }

    /// <summary>Type of block parameter: Empty, Identifier, or Expression.</summary>
    [Parameter(Mandatory = true, Position = 1)]
    public LiquidTagType Type { get; set; }

    /// <summary>
    /// Block implementation as ScriptBlock.\§
    /// The ScriptBlock receives the rendered content and must return the final text.\n
    /// - Empty: <c>param($body)</c>\n
    /// - Identifier: <c>param($identifier, $body)</c>\n
    /// - Expression: <c>param($value, $body)</c> (evaluated expression)
    /// </summary>
    [Parameter(Mandatory = true, Position = 2)]
    public ScriptBlock? ScriptBlock { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            FluidManager.RegisterCustomBlock(Name ?? string.Empty, Type, ScriptBlock!);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "RegisterLiquidBlockError", ErrorCategory.InvalidArgument, Name));
        }
    }
}
