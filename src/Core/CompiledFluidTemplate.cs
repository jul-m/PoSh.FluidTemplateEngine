using Fluid;

namespace PoSh.FluidTemplateEngine.Core;

public sealed class CompiledFluidTemplate(string? name, string source, IFluidTemplate template)
{
    public string? Name { get; } = name;

    public string Source { get; } = source;

    public IFluidTemplate Template { get; } = template;
}
