using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Allow-lists a .NET type for property access in templates.</summary>
/// <para>
/// Fluid is secure by default and only allows access to CLR members for registered types.
/// This cmdlet registers a type in the member access strategy (TemplateOptions.MemberAccessStrategy).
/// </para>
/// <example>
/// <summary>Register all public properties of a type</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-FluidType -Type ([System.Diagnostics.Process])</code>
/// </example>
/// <example>
/// <summary>Register only some properties</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-FluidType -TypeName 'System.Diagnostics.Process' -Member Id, ProcessName</code>
/// </example>
/// <example>
/// <summary>Render a CLR object directly after registration</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Register-FluidType -TypeName 'System.Version' -Member Major, Minor
/// Format-LiquidString -Source '{{ v.Major }}.{{ v.Minor }}' -Model @{ v = [Version]'1.2.3' }</code>
/// </example>
[Cmdlet(VerbsLifecycle.Register, "FluidType", DefaultParameterSetName = ParameterSetByType)]
public sealed class RegisterFluidTypeCmdlet : PSCmdlet
{
    private const string ParameterSetByType = "ByType";
    private const string ParameterSetByName = "ByName";

    /// <summary>.NET type to register (e.g. <c>[MyType]</c>).</summary>
    [Parameter(Mandatory = true, ParameterSetName = ParameterSetByType, Position = 0)]
    public Type? Type { get; set; }

    /// <summary>Name of the .NET type to register (e.g. <c>System.Version</c>).</summary>
    [Parameter(Mandatory = true, ParameterSetName = ParameterSetByName, Position = 0)]
    public string? TypeName { get; set; }

    /// <summary>
    /// List of allowed properties. If omitted, all public properties are registered.
    /// </summary>
    [Parameter(Mandatory = false)]
    public string[]? Member { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            var resolvedType = ResolveType();
            var typeKey = resolvedType.AssemblyQualifiedName ?? resolvedType.FullName ?? resolvedType.Name;

            IReadOnlyList<string>? members = null;
            if (Member is { Length: > 0 })
            {
                var cleaned = Member
                    .Select(m => m?.Trim())
                    .Where(m => !string.IsNullOrWhiteSpace(m))
                    .Select(m => m!)
                    .Distinct(StringComparer.Ordinal)
                    .ToArray();

                if (cleaned.Length > 0)
                {
                    members = cleaned;
                }
            }

            var config = FluidModuleConfiguration.GetInstance(SessionState);

            config.MemberAccess.RemoveAll(r => string.Equals(r.TypeName, typeKey, StringComparison.OrdinalIgnoreCase));
            config.MemberAccess.Add(new MemberAccessRegistration(typeKey, members));
        }
        catch (Exception ex)
        {
            var target = (object?)TypeName ?? Type;
            WriteError(new ErrorRecord(ex, "RegisterFluidTypeError", ErrorCategory.InvalidArgument, target));
        }
    }

    private Type ResolveType()
    {
        if (Type != null)
        {
            return Type;
        }

        var name = TypeName?.Trim();
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("TypeName cannot be null or empty.", nameof(TypeName));
        }

        // Try full name / assembly-qualified name first.
        var resolved = System.Type.GetType(name, throwOnError: false, ignoreCase: true);
        if (resolved != null)
        {
            return resolved;
        }

        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
        {
            resolved = asm.GetType(name, throwOnError: false, ignoreCase: true);
            if (resolved != null)
            {
                return resolved;
            }
        }

        throw new InvalidOperationException($"Unable to resolve .NET type '{name}'.");
    }
}
