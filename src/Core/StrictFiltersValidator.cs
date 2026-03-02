using Fluid;
using Fluid.Ast;

namespace PoSh.FluidTemplateEngine.Core;

internal static class StrictFiltersValidator
{
    public static void Validate(IFluidTemplate template, FilterCollection filters)
    {
        var visitor = new UnknownFilterVisitor(filters);
        visitor.VisitTemplate(template);

        if (visitor.UnknownFilters.Count == 0)
        {
            return;
        }

        // Keep the error simple and deterministic.
        var first = visitor.UnknownFilters[0];
        throw new InvalidOperationException($"Undefined filter '{first}'");
    }

    private sealed class UnknownFilterVisitor(FilterCollection filters) : AstVisitor
    {
        private readonly FilterCollection _filters = filters;

        public List<string> UnknownFilters { get; } = new();

        protected override Expression VisitFilterExpression(FilterExpression filterExpression)
        {
            if (!_filters.TryGetValue(filterExpression.Name, out _))
            {
                if (!UnknownFilters.Contains(filterExpression.Name, StringComparer.Ordinal))
                {
                    UnknownFilters.Add(filterExpression.Name);
                }
            }

            return base.VisitFilterExpression(filterExpression);
        }
    }
}
