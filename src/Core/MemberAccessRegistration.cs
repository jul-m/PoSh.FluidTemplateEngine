namespace PoSh.FluidTemplateEngine.Core;

public sealed class MemberAccessRegistration(string typeName, IReadOnlyList<string>? members)
{
    public string TypeName { get; } = typeName;

    /// <summary>
    /// Null or empty means "all public properties".
    /// </summary>
    public IReadOnlyList<string>? Members { get; } = members;
}
