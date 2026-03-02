using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Registers a custom Liquid tag (without closing block).</summary>
/// <para>
/// A tag is a Liquid element without internal content (no <c>{%% end... %%}</c>).
/// The ScriptBlock returns the text to write in the rendering.
/// </para>
/// <para>
/// Three tag types are supported :
/// <list type="bullet">
///   <item>
///     <term>Empty</term>
///     <description>
///       Tag with no parameter. ScriptBlock receives no argument.
///       E.g.: <c>{%% mytag %%}</c>
///     </description>
///   </item>
///   <item>
///     <term>Identifier</term>
///     <description>
///       Tag with an identifier. ScriptBlock receives <c>$identifier</c>.
///       E.g.: <c>{%% hello world %%}</c>
///     </description>
///   </item>
///   <item>
///     <term>Expression</term>
///     <description>
///       Tag with an evaluated expression. ScriptBlock receives <c>$value</c>.
///       E.g.: <c>{%% echo 'text' | upcase %%}</c>
///     </description>
///   </item>
/// </list>
/// </para>
/// <example>
/// <summary>Empty tag</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidTag -Name 'timestamp' -Type Empty -ScriptBlock {
///     (Get-Date).ToString('o')
/// }
/// </code>
/// </example>
/// <example>
/// <summary>Tag with identifier</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
///     param($identifier)
///     "Hello $identifier!"
/// }
/// </code>
/// </example>
/// <example>
/// <summary>Tag with expression</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
///     param($value)
///     "[$value]"
/// }
/// </code>
/// </example>
/// <seealso cref="RegisterLiquidBlockCmdlet" />
/// <seealso cref="RegisterLiquidFilterCmdlet" />
[Cmdlet(VerbsLifecycle.Register, "LiquidTag")]
public sealed class RegisterLiquidTagCmdlet : PSCmdlet
{
    /// <summary>Name of the tag (e.g. <c>hello</c>, <c>timestamp</c>).</summary>
    [Parameter(Mandatory = true, Position = 0)]
    public string? Name { get; set; }

    /// <summary>Type of tag parameter: Empty, Identifier, or Expression.</summary>
    [Parameter(Mandatory = true, Position = 1)]
    public LiquidTagType Type { get; set; }

    /// <summary>
    /// Tag implementation as ScriptBlock.\§
    /// The ScriptBlock must return the text to write.\n
    /// - Empty: no argument\n
    /// - Identifier: <c>param($identifier)</c>\n
    /// - Expression: <c>param($value)</c> (evaluated expression)
    /// </summary>
    [Parameter(Mandatory = true, Position = 2)]
    public ScriptBlock? ScriptBlock { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            FluidManager.RegisterCustomTag(Name ?? string.Empty, Type, ScriptBlock!);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "RegisterLiquidTagError", ErrorCategory.InvalidArgument, Name));
        }
    }
}
