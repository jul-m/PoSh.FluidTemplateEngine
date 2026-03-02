using Fluid;

namespace PoSh.FluidTemplateEngine.Core;

internal sealed class ValidatingTemplateCache(
    ITemplateCache inner,
    FilterCollection filters,
    Func<bool> strictFiltersEnabled) : ITemplateCache
{
    private readonly ITemplateCache _inner = inner ?? throw new ArgumentNullException(nameof(inner));
    private readonly FilterCollection _filters = filters ?? throw new ArgumentNullException(nameof(filters));
    private readonly Func<bool> _strictFiltersEnabled =
        strictFiltersEnabled ??
            throw new ArgumentNullException(nameof(strictFiltersEnabled));

    public bool TryGetTemplate(string subpath, DateTimeOffset lastModified, out IFluidTemplate template)
        => _inner.TryGetTemplate(subpath, lastModified, out template);

    public void SetTemplate(string subpath, DateTimeOffset lastModified, IFluidTemplate template)
    {
        if (_strictFiltersEnabled())
        {
            StrictFiltersValidator.Validate(template, _filters);
        }

        _inner.SetTemplate(subpath, lastModified, template);
    }
}
