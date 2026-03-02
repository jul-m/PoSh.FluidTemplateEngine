using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Registers a custom Liquid filter (ScriptBlock).</summary>
/// <para>
/// The ScriptBlock receives as first argument the input value, then the
/// positional arguments of the filter.
/// </para>
/// <para>Liquid example: <c>{{ name | shout }}</c></para>
/// <example>
/// <summary>Create a shout filter</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-LiquidFilter -Name 'shout' -ScriptBlock { param($input) $input.ToString().ToUpperInvariant() }</code>
/// </example>
/// <example>
/// <summary>Filter with arguments</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-LiquidFilter -Name 'prefix' -ScriptBlock { param($input, $p) "$p$input" }</code>
/// </example>
/// <seealso cref="FormatLiquidStringCmdlet" />
[Cmdlet(VerbsLifecycle.Register, "LiquidFilter")]
public sealed class RegisterLiquidFilterCmdlet : PSCmdlet
{
    /// <summary>Name of the filter (e.g. <c>shout</c>, <c>prefix</c>).</summary>
    [Parameter(Mandatory = true, Position = 0)]
    public string? Name { get; set; }

    /// <summary>Filter implementation as ScriptBlock.</summary>
    [Parameter(Mandatory = true, Position = 1)]
    public ScriptBlock? ScriptBlock { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            FluidManager.RegisterScriptFilter(Name ?? string.Empty, ScriptBlock!);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "RegisterLiquidFilterError", ErrorCategory.InvalidArgument, Name));
        }
    }
}
