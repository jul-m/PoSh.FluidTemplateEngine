using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Registers a custom Liquid binary operator.</summary>
/// <para>
/// Operators are used in Liquid conditions to compare values (e.g.: <c>==</c>, <c>contains</c>).
/// The ScriptBlock receives the two operands and must return a boolean.
/// </para>
/// <example>
/// <summary>Custom XOR operator</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-LiquidOperator -Name 'xor' -ScriptBlock { param($left, $right) [bool]$left -xor [bool]$right }
/// Format-LiquidString -Source "{% if true xor false %}Yes{% endif %}" -Model @{}</code>
/// </example>
/// <example>
/// <summary>Custom "matches" operator (regex)</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-LiquidOperator -Name 'matches' -ScriptBlock { param($left, $right) $left -match $right }
/// Format-LiquidString -Source "{% if name matches '^A' %}Starts with A{% endif %}" -Model @{ name = 'Alice' }</code>
/// </example>
/// <seealso cref="RegisterLiquidTagCmdlet" />
/// <seealso cref="RegisterLiquidFilterCmdlet" />
[Cmdlet(VerbsLifecycle.Register, "LiquidOperator")]
public sealed class RegisterLiquidOperatorCmdlet : PSCmdlet
{
    /// <summary>Operator keyword (e.g. <c>xor</c>, <c>matches</c>).</summary>
    [Parameter(Mandatory = true, Position = 0)]
    public string? Name { get; set; }

    /// <summary>
    /// Comparison implementation as ScriptBlock.\§
    /// The ScriptBlock receives <c>param($left, $right)</c> and must return a boolean.
    /// </summary>
    [Parameter(Mandatory = true, Position = 1)]
    public ScriptBlock? ScriptBlock { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            FluidManager.RegisterCustomOperator(Name ?? string.Empty, ScriptBlock!);
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "RegisterLiquidOperatorError", ErrorCategory.InvalidArgument, Name));
        }
    }
}
