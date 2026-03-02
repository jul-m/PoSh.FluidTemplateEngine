using System.Management.Automation;
using Fluid;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Compiles a Liquid template into a reusable template.</summary>
/// <para>The result can be passed to <c>Invoke-FluidTemplate</c>, including via the pipeline.</para>
/// <example>
/// <summary>Compile a template</summary>
/// <prefix>PS&gt; </prefix>
/// <code>$tpl = New-FluidTemplate -Source 'Hi {{ name }}'</code>
/// </example>
/// <example>
/// <summary>Compile then render</summary>
/// <prefix>PS&gt; </prefix>
/// <code>New-FluidTemplate -Source 'Hi {{ name }}' | Invoke-FluidTemplate -Model @{ name = 'Bob' }</code>
/// </example>
/// <seealso cref="InvokeFluidTemplateCmdlet" />
[Cmdlet(VerbsCommon.New, "FluidTemplate")]
[OutputType(typeof(CompiledFluidTemplate))]
public sealed class NewFluidTemplateCmdlet : PSCmdlet
{
    /// <summary>The source code of the Liquid template.</summary>
    [Parameter(Mandatory = true, Position = 0)]
    public string? Source { get; set; }

    /// <summary>Optional name (metadata) associated with the compiled template.</summary>
    [Parameter(Mandatory = false)]
    public string? Name { get; set; }

    /// <summary>Root directory for templates for <c>include</c>/<c>render</c> tags.</summary>
    [Parameter(Mandatory = false)]
    public string? TemplateRoot { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            var (parser, options) = FluidManager.GetEngine(SessionState, TemplateRoot);

            if (!parser.TryParse(Source ?? string.Empty, out var template, out var error))
            {
                ThrowTerminatingError(new ErrorRecord(
                    new System.Management.Automation.ParseException(error),
                    "FluidTemplateParseError",
                    ErrorCategory.ParserError,
                    Source
                ));
                return;
            }

            FluidManager.ValidateStrictFiltersIfEnabled(SessionState, template, options);

            WriteObject(new CompiledFluidTemplate(Name, Source ?? string.Empty, template));
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "NewFluidTemplateError", ErrorCategory.InvalidOperation, Source));
        }
    }
}
