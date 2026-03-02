using System.Management.Automation;
using System.Text.Encodings.Web;
using Fluid;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Parses and renders a Liquid template (in one step).</summary>
/// <para>This cmdlet parses then renders a Liquid template via Fluid.</para>
/// <para>By default, the output is not encoded. Use <c>-HtmlEncode</c> to enable HTML encoding.</para>
/// <example>
/// <summary>Render a Liquid string</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Format-LiquidString -Source 'Hello {{ name }}' -Model @{ name = 'Alice' }</code>
/// </example>
/// <example>
/// <summary>Enable HTML encoding</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Format-LiquidString -Source '{{ value }}' -Model @{ value = '&lt;tag&gt;' } -HtmlEncode</code>
/// </example>
[Cmdlet(VerbsCommon.Format, "LiquidString", DefaultParameterSetName = "Default")]
[OutputType(typeof(string))]
public sealed class FormatLiquidStringCmdlet : PSCmdlet
{
    /// <summary>The source code of the Liquid template.</summary>
    [Parameter(Mandatory = true, Position = 0, ParameterSetName = "Default")]
    [Parameter(Mandatory = true, Position = 0, ParameterSetName = "HtmlEncoded")]
    [Parameter(Mandatory = true, Position = 0, ParameterSetName = "NoEncoding")]
    public string? Source { get; set; }

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
            var (parser, _) = FluidManager.GetEngine(SessionState, TemplateRoot);
            if (!parser.TryParse(Source ?? string.Empty, out var template, out var error))
            {
                ThrowTerminatingError(new ErrorRecord(
                    new System.Management.Automation.ParseException(error),
                    "LiquidStringParseError",
                    ErrorCategory.ParserError,
                    Source
                ));
                return;
            }

            var (_, options) = FluidManager.GetEngine(SessionState, TemplateRoot);
            FluidManager.ValidateStrictFiltersIfEnabled(SessionState, template, options);
            var modelDict = PsModelConverter.ToDictionary(Model);
            var context = new TemplateContext(options);
            foreach (var kvp in modelDict)
            {
                context.SetValue(kvp.Key, kvp.Value);
            }

            using var writer = new StringWriter();
            TextEncoder encoder = HtmlEncode.IsPresent ? HtmlEncoder.Default : NullEncoder.Default;
            template.RenderAsync(writer, encoder, context).AsTask().GetAwaiter().GetResult();
            WriteObject(writer.ToString());
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "FormatLiquidStringError", ErrorCategory.InvalidOperation, Source));
        }
    }
}
