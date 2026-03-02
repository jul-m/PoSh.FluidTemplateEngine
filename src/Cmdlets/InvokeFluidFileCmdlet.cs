using System.Management.Automation;
using System.Text.Encodings.Web;
using Fluid;
using PoSh.FluidTemplateEngine.Core;

namespace PoSh.FluidTemplateEngine.Cmdlets;

/// <summary>Renders a Liquid template from a file.</summary>
/// <para>By default, <c>-TemplateRoot</c> is deduced from the file's folder (useful for <c>{% include %}</c>).</para>
/// <example>
/// <summary>Render a .liquid file</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Invoke-FluidFile -Path './templates/main.liquid' -Model @{ value = 'X' }</code>
/// </example>
/// <example>
/// <summary>Render with an explicit include root</summary>
/// <prefix>PS&gt; </prefix>
/// <code>Invoke-FluidFile -Path './templates/main.liquid' -TemplateRoot './templates' -Model @{ value = 'X' }</code>
/// </example>
/// <seealso cref="SetFluidModuleConfigCmdlet" />
[Cmdlet(VerbsLifecycle.Invoke, "FluidFile", DefaultParameterSetName = "Default")]
[OutputType(typeof(string))]
public sealed class InvokeFluidFileCmdlet : PSCmdlet
{
    /// <summary>Path to the template file to render.</summary>
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "Default")]
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "HtmlEncoded")]
    [Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true, ValueFromPipelineByPropertyName = true, ParameterSetName = "NoEncoding")]
    [Alias("FullName")]
    public string? Path { get; set; }

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
            var resolvedPath = GetUnresolvedProviderPathFromPSPath(Path ?? string.Empty);
            if (!File.Exists(resolvedPath))
            {
                throw new FileNotFoundException($"Template file not found: {resolvedPath}");
            }

            var source = File.ReadAllText(resolvedPath);

            var effectiveRoot = TemplateRoot;
            if (string.IsNullOrWhiteSpace(effectiveRoot))
            {
                effectiveRoot = System.IO.Path.GetDirectoryName(resolvedPath);
            }

            var (parser, _) = FluidManager.GetEngine(SessionState, effectiveRoot);
            if (!parser.TryParse(source, out var template, out var error))
            {
                ThrowTerminatingError(new ErrorRecord(
                    new System.Management.Automation.ParseException(error),
                    "FluidFileParseError",
                    ErrorCategory.ParserError,
                    resolvedPath
                ));
                return;
            }

            var (_, options) = FluidManager.GetEngine(SessionState, effectiveRoot);
            FluidManager.ValidateStrictFiltersIfEnabled(SessionState, template, options);
            var modelDict = PsModelConverter.ToDictionary(Model);
            var context = new TemplateContext(options);
            foreach (var kvp in modelDict)
            {
                context.SetValue(kvp.Key, kvp.Value);
            }

            using var writer = new StringWriter();
            TextEncoder encoder = HtmlEncode.IsPresent ? HtmlEncoder.Default : NullEncoder.Default;
            // RenderAsync returns a ValueTask; convert to a Task before blocking to ensure
            // we wait for completion (avoids CA2012 warnings).
            template.RenderAsync(writer, encoder, context).AsTask().GetAwaiter().GetResult();
            WriteObject(writer.ToString());
        }
        catch (Exception ex)
        {
            WriteError(new ErrorRecord(ex, "InvokeFluidFileError", ErrorCategory.OpenError, Path));
        }
    }
}
