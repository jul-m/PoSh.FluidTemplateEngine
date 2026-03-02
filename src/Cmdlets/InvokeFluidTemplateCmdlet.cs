using System.IO;
using System.Management.Automation;
using System.Text.Encodings.Web;
using Fluid;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Renders a compiled Liquid template with a model.</summary>
/// <para>
/// Accepts as input a template from <c>New-FluidTemplate</c> (pipeline) or a
/// Fluid <c>IFluidTemplate</c> instance.
/// </para>
/// <example>
/// <summary>Render a compiled template</summary>
/// <prefix>PS&gt; </prefix>
/// <code>New-FluidTemplate -Source 'Hi {{ name }}' | Invoke-FluidTemplate -Model @{ name = 'Bob' }</code>
/// </example>
/// <example>
/// <summary>Rendering with HTML encoding</summary>
/// <prefix>PS&gt; </prefix>
/// <code>
/// New-FluidTemplate -Source '{{ value }}' |
///     Invoke-FluidTemplate -Model @{ value = '&lt;tag&gt;' } -HtmlEncode
/// </code>
/// </example>
/// <seealso cref="NewFluidTemplateCmdlet" />
/// <seealso cref="FormatLiquidStringCmdlet" />
[Cmdlet(VerbsLifecycle.Invoke, "FluidTemplate", DefaultParameterSetName = "Default")]
[OutputType(typeof(string))]
public sealed class InvokeFluidTemplateCmdlet : PSCmdlet
{
    /// <summary>The compiled template (or an <c>IFluidTemplate</c>).</summary>
    [Parameter(Mandatory = true, ValueFromPipeline = true, Position = 0, ParameterSetName = "Default")]
    [Parameter(Mandatory = true, ValueFromPipeline = true, Position = 0, ParameterSetName = "HtmlEncoded")]
    [Parameter(Mandatory = true, ValueFromPipeline = true, Position = 0, ParameterSetName = "NoEncoding")]
    public object? Template { get; set; }

    /// <summary>The model (hashtable, PSCustomObject, or object) exposed to the template.</summary>
    [Parameter(Mandatory = true)]
    public object? Model { get; set; }

    /// <summary>Enables HTML encoding (HtmlEncoder.Default) during rendering.</summary>
    [Parameter(Mandatory = true, ParameterSetName = "HtmlEncoded")]
    public SwitchParameter HtmlEncode { get; set; }

    /// <summary>
    /// Backward compatibility with old PowerShell wrapper.
    /// Has no effect as encoding is disabled by default.
    /// </summary>
    [Parameter(Mandatory = true, ParameterSetName = "NoEncoding")]
    public SwitchParameter NoEncoding { get; set; }

    /// <summary>Root directory for templates for <c>include</c>/<c>render</c> tags.</summary>
    [Parameter()]
    public string? TemplateRoot { get; set; }

    protected override void ProcessRecord()
    {
        try
        {
            var (_, options) = FluidManager.GetEngine(SessionState, TemplateRoot);
            var fluidTemplate = UnwrapTemplate(Template);

            var modelDict = PsModelConverter.ToDictionary(Model);
            var context = new TemplateContext(options);
            foreach (var kvp in modelDict)
            {
                context.SetValue(kvp.Key, kvp.Value);
            }

            using var writer = new StringWriter();
            TextEncoder encoder = HtmlEncode.IsPresent ? HtmlEncoder.Default : NullEncoder.Default;
            fluidTemplate.RenderAsync(writer, encoder, context).AsTask().GetAwaiter().GetResult();
            WriteObject(writer.ToString());
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "InvokeFluidTemplateError", ErrorCategory.InvalidOperation, Template));
        }
    }

    private static IFluidTemplate UnwrapTemplate(object? value)
    {
        if (value is PSObject psObject)
        {
            return UnwrapTemplate(psObject.BaseObject);
        }

        return value switch
        {
            CompiledFluidTemplate compiled => compiled.Template,
            IFluidTemplate fluidTemplate => fluidTemplate,
            _ => throw new ArgumentException("Template must be a CompiledFluidTemplate or an IFluidTemplate.")
        };
    }
}
