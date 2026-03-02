using System.Management.Automation;
using Fluid;

namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// Represents the global configuration for the PoSh.FluidTemplateEngine module.
/// Stored in a PowerShell global variable for persistence within a session.
/// </summary>
public sealed class FluidModuleConfiguration
{
    public string? TemplateRoot { get; set; }

    public bool StrictVariables { get; set; } = false;

    public bool StrictFilters { get; set; } = false;

    public int? MaxSteps { get; set; } = null;

    public int? MaxRecursion { get; set; } = null;

    public bool AllowFunctions { get; set; } = false;

    public bool AllowParentheses { get; set; } = false;

    /// <summary>
    /// Optional fallback format returned when an undefined variable is accessed (when StrictVariables is false).
    /// Use the placeholder <c>{name}</c> to include the variable path.
    /// Example: <c>[{name} not found]</c>
    /// </summary>
    public string? UndefinedFormat { get; set; }

    /// <summary>
    /// Culture name (e.g. "fr-FR", "en-US") used for rendering dates/numbers.
    /// When null/empty, Fluid's default culture is used.
    /// </summary>
    public string? CultureName { get; set; }

    /// <summary>
    /// System time zone identifier used when parsing date strings without an explicit time zone.
    /// Examples: "Europe/Paris" (macOS/Linux), "Pacific Standard Time" (Windows).
    /// When null/empty, Fluid's default time zone is used.
    /// </summary>
    public string? TimeZoneId { get; set; }

    /// <summary>
    /// Default whitespace trimming rules (see Fluid README: TemplateOptions.Trimming).
    /// </summary>
    public TrimmingFlags Trimming { get; set; } = TrimmingFlags.None;

    /// <summary>
    /// When true, trimming removes all successive blank chars. Default is true.
    /// </summary>
    public bool Greedy { get; set; } = true;

    /// <summary>
    /// How Fluid compares model/context property names.
    /// </summary>
    public ModelNamesComparerMode ModelNamesComparer { get; set; } = ModelNamesComparerMode.OrdinalIgnoreCase;

    /// <summary>
    /// When true, member access on registered .NET types ignores casing.
    /// </summary>
    public bool IgnoreMemberCasing { get; set; } = false;

    /// <summary>
    /// When true, the built-in 'json' filter outputs indented JSON.
    /// </summary>
    public bool JsonIndented { get; set; } = false;

    /// <summary>
    /// When true, the built-in 'json' filter uses UnsafeRelaxedJsonEscaping.
    /// </summary>
    public bool JsonRelaxedEscaping { get; set; } = false;

    /// <summary>
    /// Allow-list registrations for accessing members on CLR objects.
    /// </summary>
    public List<MemberAccessRegistration> MemberAccess { get; } = new();

    public void Reset()
    {
        TemplateRoot = null;
        StrictVariables = false;
        StrictFilters = false;
        MaxSteps = null;
        MaxRecursion = null;
        AllowFunctions = false;
        AllowParentheses = false;
        UndefinedFormat = null;
        CultureName = null;
        TimeZoneId = null;
        Trimming = TrimmingFlags.None;
        Greedy = true;
        ModelNamesComparer = ModelNamesComparerMode.OrdinalIgnoreCase;
        IgnoreMemberCasing = false;
        JsonIndented = false;
        JsonRelaxedEscaping = false;
        MemberAccess.Clear();
    }

    public static FluidModuleConfiguration GetInstance(SessionState sessionState)
    {
        const string varName = "Global:FluidModuleConfiguration";

        if (sessionState.PSVariable.GetValue(varName) is not FluidModuleConfiguration instance)
        {
            instance = new FluidModuleConfiguration();
            sessionState.PSVariable.Set(varName, instance);
        }

        return instance;
    }
}
