using System.Management.Automation;
using Fluid;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Configures the global configuration of the PoSh.FluidTemplateEngine module.</summary>
/// <para>These options influence parsing/rendering (includes, strict modes, execution limits, etc.).</para>
/// <example>
/// <summary>Set a root for includes</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Set-FluidModuleConfig -TemplateRoot './templates'</code>
/// </example>
/// <example>
/// <summary>Enable strict modes</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Set-FluidModuleConfig -StrictVariables -StrictFilters</code>
/// </example>
/// <example>
/// <summary>Limit execution</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Set-FluidModuleConfig -MaxSteps 100000 -MaxRecursion 20</code>
/// </example>
/// <example>
/// <summary>Reset</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Set-FluidModuleConfig -Reset</code>
/// </example>
/// <seealso cref="GetFluidModuleConfigCmdlet" />
[Cmdlet(VerbsCommon.Set, "FluidModuleConfig")]
public sealed class SetFluidModuleConfigCmdlet : PSCmdlet
{
    /// <summary>Root directory for templates for <c>include</c>/<c>render</c> tags.</summary>
    [Parameter(Mandatory = false)]
    public string? TemplateRoot { get; set; }

    /// <summary>Enables strict mode: access to an unknown variable fails.</summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter StrictVariables { get; set; }

    /// <summary>Enables strict mode: use of an unknown filter fails.</summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter StrictFilters { get; set; }

    /// <summary>Maximum number of execution steps of a template (0 = unlimited).</summary>
    [Parameter(Mandatory = false)]
    public int? MaxSteps { get; set; }

    /// <summary>Max recursion depth (includes/renders) (null = Fluid default).</summary>
    [Parameter(Mandatory = false)]
    public int? MaxRecursion { get; set; }

    /// <summary>Allows functions (FluidParserOptions.AllowFunctions) during parsing.</summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter AllowFunctions { get; set; }

    /// <summary>Allows parentheses (FluidParserOptions.AllowParentheses) during parsing.</summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter AllowParentheses { get; set; }

    /// <summary>
    /// Fallback value when a variable is undefined (if <c>-StrictVariables</c> is disabled).
    /// Use the placeholder <c>{name}</c> to include the path.
    /// Example: <c>[{name} not found]</c>
    /// </summary>
    [Parameter(Mandatory = false)]
    public string? UndefinedFormat { get; set; }

    /// <summary>Culture used for rendering (e.g.: "fr-FR", "en-US").</summary>
    [Parameter(Mandatory = false)]
    public string? Culture { get; set; }

    /// <summary>System time zone used to parse dates without an explicit time zone (e.g.: "Europe/Paris").</summary>
    [Parameter(Mandatory = false)]
    [Alias("TimeZone")]
    public string? TimeZoneId { get; set; }

    /// <summary>Default trimming rules (Fluid TemplateOptions.Trimming).</summary>
    [Parameter(Mandatory = false)]
    public TrimmingFlags Trimming { get; set; }

    /// <summary>Enables/disables greedy mode for trimming (default: true).</summary>
    [Parameter(Mandatory = false)]
    public bool? Greedy { get; set; }

    /// <summary>Comparer used for property names (ModelNamesComparer).</summary>
    [Parameter(Mandatory = false)]
    public ModelNamesComparerMode? ModelNamesComparer { get; set; }

    /// <summary>Ignores casing when accessing members on registered .NET types.</summary>
    [Parameter(Mandatory = false)]
    public bool? IgnoreMemberCasing { get; set; }

    /// <summary>Enables/disables indented JSON for the <c>json</c> filter.</summary>
    [Parameter(Mandatory = false)]
    public bool? JsonIndented { get; set; }

    /// <summary>
    /// Enables/disables relaxed JSON encoding (UnsafeRelaxedJsonEscaping) for
    /// the <c>json</c> filter.
    /// </summary>
    [Parameter(Mandatory = false)]
    public bool? JsonRelaxedEscaping { get; set; }

    /// <summary>Resets the configuration to default values.</summary>
    [Parameter(Mandatory = false)]
    public SwitchParameter Reset { get; set; }

    protected override void ProcessRecord()
    {
        var config = FluidModuleConfiguration.GetInstance(SessionState);

        if (Reset.IsPresent)
        {
            config.Reset();
        }

        if (TemplateRoot != null)
        {
            config.TemplateRoot = TemplateRoot;
        }

        if (MyInvocation.BoundParameters.ContainsKey(nameof(StrictVariables)))
        {
            config.StrictVariables = StrictVariables.IsPresent;
        }

        if (MyInvocation.BoundParameters.ContainsKey(nameof(StrictFilters)))
        {
            config.StrictFilters = StrictFilters.IsPresent;
        }

        if (MaxSteps != null)
        {
            config.MaxSteps = MaxSteps;
        }

        if (MaxRecursion != null)
        {
            config.MaxRecursion = MaxRecursion;
        }

        if (MyInvocation.BoundParameters.ContainsKey(nameof(AllowFunctions)))
        {
            config.AllowFunctions = AllowFunctions.IsPresent;
        }

        if (MyInvocation.BoundParameters.ContainsKey(nameof(AllowParentheses)))
        {
            config.AllowParentheses = AllowParentheses.IsPresent;
        }

        if (UndefinedFormat != null)
        {
            config.UndefinedFormat = string.IsNullOrWhiteSpace(UndefinedFormat) ? null : UndefinedFormat;
        }

        if (Culture != null)
        {
            config.CultureName = string.IsNullOrWhiteSpace(Culture) ? null : Culture;
        }

        if (TimeZoneId != null)
        {
            config.TimeZoneId = string.IsNullOrWhiteSpace(TimeZoneId) ? null : TimeZoneId;
        }

        if (MyInvocation.BoundParameters.ContainsKey(nameof(Trimming)))
        {
            config.Trimming = Trimming;
        }

        if (Greedy != null)
        {
            config.Greedy = Greedy.Value;
        }

        if (ModelNamesComparer != null)
        {
            config.ModelNamesComparer = ModelNamesComparer.Value;
        }

        if (IgnoreMemberCasing != null)
        {
            config.IgnoreMemberCasing = IgnoreMemberCasing.Value;
        }

        if (JsonIndented != null)
        {
            config.JsonIndented = JsonIndented.Value;
        }

        if (JsonRelaxedEscaping != null)
        {
            config.JsonRelaxedEscaping = JsonRelaxedEscaping.Value;
        }
    }
}
