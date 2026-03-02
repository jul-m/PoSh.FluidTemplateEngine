using System.Management.Automation;

namespace PoSh.FluidTemplateEngine.Core;

public static class ModuleConfigResolver
{
    public static string ResolveTemplateRoot(string? providedValue, SessionState sessionState)
    {
        if (!string.IsNullOrWhiteSpace(providedValue))
        {
            return providedValue;
        }

        var config = FluidModuleConfiguration.GetInstance(sessionState);
        if (!string.IsNullOrWhiteSpace(config.TemplateRoot))
        {
            return config.TemplateRoot;
        }

        return sessionState.Path.CurrentFileSystemLocation.Path;
    }
}
