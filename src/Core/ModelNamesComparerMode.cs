namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// Defines which <see cref="System.StringComparer"/> is used to compare
/// variable/property names exposed to the Liquid context (Fluid
/// TemplateOptions.ModelNamesComparer).
/// </summary>
public enum ModelNamesComparerMode
{
    /// <summary><see cref="System.StringComparer.OrdinalIgnoreCase"/> (default).</summary>
    OrdinalIgnoreCase,

    /// <summary><see cref="System.StringComparer.Ordinal"/>.</summary>
    Ordinal,

    /// <summary><see cref="System.StringComparer.InvariantCultureIgnoreCase"/>.</summary>
    InvariantCultureIgnoreCase,

    /// <summary><see cref="System.StringComparer.InvariantCulture"/>.</summary>
    InvariantCulture,

    /// <summary><see cref="System.StringComparer.CurrentCultureIgnoreCase"/>.</summary>
    CurrentCultureIgnoreCase,

    /// <summary><see cref="System.StringComparer.CurrentCulture"/>.</summary>
    CurrentCulture,
}
