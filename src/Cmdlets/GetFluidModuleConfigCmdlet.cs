using System.Management.Automation;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Displays the global configuration of the PoSh.FluidTemplateEngine module.</summary>
/// <para>The configuration is stored in the current PowerShell session and is used by default by other cmdlets.</para>
/// <example>
/// <summary>Display the current configuration</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Get-FluidModuleConfig</code>
/// </example>
/// <seealso cref="SetFluidModuleConfigCmdlet" />
[Cmdlet(VerbsCommon.Get, "FluidModuleConfig")]
[OutputType(typeof(FluidModuleConfiguration))]
public sealed class GetFluidModuleConfigCmdlet : PSCmdlet
{
    protected override void ProcessRecord()
    {
        WriteObject(FluidModuleConfiguration.GetInstance(SessionState));
    }
}
