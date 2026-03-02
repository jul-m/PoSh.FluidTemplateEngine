using System.Collections.Concurrent;
using System.Globalization;
using System.Linq;
using System.Management.Automation;
using System.Text.Encodings.Web;
using System.Text.Json;
using Fluid;
using Fluid.Ast;
using Fluid.Values;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.FileProviders.Physical;

namespace PoSh.FluidTemplateEngine.Core;

internal static class FluidManager
{
    private static readonly object Sync = new();

    private static string? _engineKey;
    private static FluidParser? _parser;
    private static TemplateOptions? _options;

    private static readonly ConcurrentDictionary<string, FilterDelegate>
        RegisteredScriptFilters = new(StringComparer.Ordinal);
    private static readonly ConcurrentDictionary<string, CustomTagRegistration>
        RegisteredCustomTags = new(StringComparer.Ordinal);
    private static readonly ConcurrentDictionary<string, CustomBlockRegistration>
        RegisteredCustomBlocks = new(StringComparer.Ordinal);
    private static readonly ConcurrentDictionary<string, ScriptBlock>
        RegisteredCustomOperators = new(StringComparer.Ordinal);

    public static (FluidParser Parser, TemplateOptions Options) GetEngine(
        SessionState sessionState,
        string? templateRootOverride)
    {
        var config = FluidModuleConfiguration.GetInstance(sessionState);
        var templateRoot = ModuleConfigResolver.ResolveTemplateRoot(templateRootOverride, sessionState);

        static string FingerprintMemberAccess(IReadOnlyList<MemberAccessRegistration> registrations)
        {
            if (registrations.Count == 0)
            {
                return string.Empty;
            }

            return string.Join(";", registrations
                .OrderBy(r => r.TypeName, StringComparer.Ordinal)
                .Select(r =>
                {
                    var members = r.Members is { Count: > 0 }
                        ? string.Join(",", r.Members.OrderBy(m => m, StringComparer.Ordinal))
                        : "*";

                    return $"{r.TypeName}:[{members}]";
                }));
        }

        static StringComparer ResolveModelNamesComparer(ModelNamesComparerMode mode)
            => mode switch
            {
                ModelNamesComparerMode.OrdinalIgnoreCase => StringComparer.OrdinalIgnoreCase,
                ModelNamesComparerMode.Ordinal => StringComparer.Ordinal,
                ModelNamesComparerMode.InvariantCultureIgnoreCase => StringComparer.InvariantCultureIgnoreCase,
                ModelNamesComparerMode.InvariantCulture => StringComparer.InvariantCulture,
                ModelNamesComparerMode.CurrentCultureIgnoreCase => StringComparer.CurrentCultureIgnoreCase,
                ModelNamesComparerMode.CurrentCulture => StringComparer.CurrentCulture,
                _ => StringComparer.OrdinalIgnoreCase,
            };

        var engineKey = string.Join("|",
        [
            templateRoot,
            config.StrictVariables,
            config.StrictFilters,
            config.MaxSteps,
            config.MaxRecursion,
            config.AllowFunctions,
            config.AllowParentheses,
            config.UndefinedFormat,
            config.CultureName,
            config.TimeZoneId,
            (int)config.Trimming,
            config.Greedy,
            config.ModelNamesComparer,
            config.IgnoreMemberCasing,
            config.JsonIndented,
            config.JsonRelaxedEscaping,
            FingerprintMemberAccess(config.MemberAccess),
            string.Join(";", RegisteredCustomTags.Keys.OrderBy(k => k, StringComparer.Ordinal)),
            string.Join(";", RegisteredCustomBlocks.Keys.OrderBy(k => k, StringComparer.Ordinal)),
            string.Join(";", RegisteredCustomOperators.Keys.OrderBy(k => k, StringComparer.Ordinal)),
        ]);

        lock (Sync)
        {
            if (_parser != null && _options != null && string.Equals(_engineKey, engineKey, StringComparison.Ordinal))
            {
                return (_parser, _options);
            }

            var parserOptions = new FluidParserOptions
            {
                AllowFunctions = config.AllowFunctions,
                AllowParentheses = config.AllowParentheses,
            };

            _parser = new FluidParser(parserOptions);

            // Apply custom tags.
            foreach (var kvp in RegisteredCustomTags)
            {
                ApplyCustomTag(_parser, kvp.Value);
            }

            // Apply custom blocks.
            foreach (var kvp in RegisteredCustomBlocks)
            {
                ApplyCustomBlock(_parser, kvp.Value);
            }

            // Apply custom operators.
            foreach (var kvp in RegisteredCustomOperators)
            {
                var scriptBlock = kvp.Value;
                _parser.RegisteredOperators[kvp.Key] = (left, right) =>
                    new ScriptBlockBinaryExpression(left, right, scriptBlock);
            }

            _options = new TemplateOptions
            {
                MaxSteps = config.MaxSteps ?? 0,
                Trimming = config.Trimming,
                Greedy = config.Greedy,
                ModelNamesComparer = ResolveModelNamesComparer(config.ModelNamesComparer)
            };

            if (!string.IsNullOrWhiteSpace(config.CultureName))
            {
                _options.CultureInfo = new CultureInfo(config.CultureName);
            }

            if (!string.IsNullOrWhiteSpace(config.TimeZoneId))
            {
                _options.TimeZone = TimeZoneInfo.FindSystemTimeZoneById(config.TimeZoneId);
            }

            _options.MemberAccessStrategy.IgnoreCasing = config.IgnoreMemberCasing;
            ApplyMemberAccessRegistrations(_options.MemberAccessStrategy, config.MemberAccess);

            ApplyJsonOptions(_options, config);

            _options.Undefined = config.StrictVariables
                ? name => throw new InvalidOperationException($"Undefined variable '{name}'")
                : name =>
                {
                    if (!string.IsNullOrWhiteSpace(config.UndefinedFormat))
                    {
                        var text = config.UndefinedFormat.Replace("{name}", name, StringComparison.Ordinal);
                        return ValueTask.FromResult<FluidValue>(new StringValue(text));
                    }

                    return ValueTask.FromResult<FluidValue>(NilValue.Instance);
                };

            if (config.MaxRecursion is > 0)
            {
                _options.MaxRecursion = config.MaxRecursion.Value;
            }

            if (!string.IsNullOrWhiteSpace(templateRoot) && Directory.Exists(templateRoot))
            {
                IFileProvider fileProvider = new PhysicalFileProvider(templateRoot);
                _options.FileProvider = fileProvider;
            }

            foreach (var kvp in RegisteredScriptFilters)
            {
                _options.Filters.AddFilter(kvp.Key, kvp.Value);
            }

            // Enforce StrictFilters for templates loaded via include/render by validating cached templates.
            if (_options.TemplateCache != null)
            {
                _options.TemplateCache = new ValidatingTemplateCache(
                    inner: _options.TemplateCache,
                    filters: _options.Filters,
                    strictFiltersEnabled: () => FluidModuleConfiguration.GetInstance(sessionState).StrictFilters
                );
            }

            _engineKey = engineKey;
            return (_parser, _options);
        }
    }

    private static void ApplyMemberAccessRegistrations(
        MemberAccessStrategy strategy,
        IReadOnlyList<MemberAccessRegistration> registrations)
    {
        if (registrations.Count == 0)
        {
            return;
        }

        foreach (var registration in registrations)
        {
            var type = ResolveType(registration.TypeName);

            if (registration.Members is { Count: > 0 })
            {
                strategy.Register(type, registration.Members.ToArray());
            }
            else
            {
                strategy.Register(type);
            }
        }
    }

    private static Type ResolveType(string typeName)
    {
        var type = Type.GetType(typeName, throwOnError: false, ignoreCase: true);
        if (type != null)
        {
            return type;
        }

        foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
        {
            type = asm.GetType(typeName, throwOnError: false, ignoreCase: true);
            if (type != null)
            {
                return type;
            }
        }

        throw new InvalidOperationException($"Unable to resolve .NET type '{typeName}'.");
    }

    private static void ApplyJsonOptions(TemplateOptions options, FluidModuleConfiguration config)
    {
        JsonSerializerOptions? jsonOptions = options.JsonSerializerOptions;
        if (jsonOptions == null)
        {
            jsonOptions = new JsonSerializerOptions();
            options.JsonSerializerOptions = jsonOptions;
        }

        jsonOptions.WriteIndented = config.JsonIndented;

        var encoder = config.JsonRelaxedEscaping
            ? JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            : JavaScriptEncoder.Default;

        jsonOptions.Encoder = encoder;
    }

    public static void ValidateStrictFiltersIfEnabled(
        SessionState sessionState,
        IFluidTemplate template,
        TemplateOptions options)
    {
        var config = FluidModuleConfiguration.GetInstance(sessionState);
        if (!config.StrictFilters)
        {
            return;
        }

        StrictFiltersValidator.Validate(template, options.Filters);
    }

    public static void RegisterScriptFilter(string name, ScriptBlock scriptBlock)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("Filter name cannot be null or empty.", nameof(name));
        }

        RegisteredScriptFilters[name] = (input, arguments, context) =>
        {
            var args = new List<object?> { FluidValueToObject(input) };

            for (var i = 0; i < arguments.Count; i++)
            {
                args.Add(FluidValueToObject(arguments.At(i)));
            }

            var result = scriptBlock.InvokeReturnAsIs(args.ToArray());
            var fluidValue = FluidValue.Create(result, context.Options);
            return ValueTask.FromResult(fluidValue);
        };

        lock (Sync)
        {
            _engineKey = null;
        }
    }

    private static object? FluidValueToObject(FluidValue value)
    {
        return value.ToObjectValue();
    }

    public static void RegisterCustomTag(string name, LiquidTagType type, ScriptBlock scriptBlock)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("Tag name cannot be null or empty.", nameof(name));
        }

        RegisteredCustomTags[name] = new CustomTagRegistration(name, type, scriptBlock);

        lock (Sync)
        {
            _engineKey = null;
        }
    }

    public static void RegisterCustomBlock(string name, LiquidTagType type, ScriptBlock scriptBlock)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("Block name cannot be null or empty.", nameof(name));
        }

        RegisteredCustomBlocks[name] = new CustomBlockRegistration(name, type, scriptBlock);

        lock (Sync)
        {
            _engineKey = null;
        }
    }

    public static void RegisterCustomOperator(string name, ScriptBlock scriptBlock)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new ArgumentException("Operator name cannot be null or empty.", nameof(name));
        }

        RegisteredCustomOperators[name] = scriptBlock;

        lock (Sync)
        {
            _engineKey = null;
        }
    }

    private static void ApplyCustomTag(FluidParser parser, CustomTagRegistration reg)
    {
        switch (reg.Type)
        {
            case LiquidTagType.Empty:
                parser.RegisterEmptyTag(reg.Name, (writer, encoder, context) =>
                {
                    var result = reg.ScriptBlock.InvokeReturnAsIs();
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return new ValueTask<Completion>(Completion.Normal);
                });
                break;

            case LiquidTagType.Identifier:
                parser.RegisterIdentifierTag(reg.Name, (identifier, writer, encoder, context) =>
                {
                    var result = reg.ScriptBlock.InvokeReturnAsIs(identifier);
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return new ValueTask<Completion>(Completion.Normal);
                });
                break;

            case LiquidTagType.Expression:
                parser.RegisterExpressionTag(reg.Name, async (expression, writer, encoder, context) =>
                {
                    var fluidValue = await expression.EvaluateAsync(context);
                    var value = fluidValue.ToObjectValue();
                    var result = reg.ScriptBlock.InvokeReturnAsIs(value);
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return Completion.Normal;
                });
                break;

            default:
                throw new ArgumentOutOfRangeException(nameof(reg), $"Unsupported tag type: {reg.Type}");
        }
    }

    private static void ApplyCustomBlock(FluidParser parser, CustomBlockRegistration reg)
    {
        switch (reg.Type)
        {
            case LiquidTagType.Empty:
                parser.RegisterEmptyBlock(reg.Name, async (statements, writer, encoder, context) =>
                {
                    using var bodyWriter = new StringWriter();
                    await statements.RenderStatementsAsync(bodyWriter, encoder, context);
                    var body = bodyWriter.ToString();

                    var result = reg.ScriptBlock.InvokeReturnAsIs(body);
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return Completion.Normal;
                });
                break;

            case LiquidTagType.Identifier:
                parser.RegisterIdentifierBlock(reg.Name, async (identifier, statements, writer, encoder, context) =>
                {
                    using var bodyWriter = new StringWriter();
                    await statements.RenderStatementsAsync(bodyWriter, encoder, context);
                    var body = bodyWriter.ToString();

                    var result = reg.ScriptBlock.InvokeReturnAsIs(identifier, body);
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return Completion.Normal;
                });
                break;

            case LiquidTagType.Expression:
                parser.RegisterExpressionBlock(reg.Name, async (expression, statements, writer, encoder, context) =>
                {
                    var fluidValue = await expression.EvaluateAsync(context);
                    var value = fluidValue.ToObjectValue();

                    using var bodyWriter = new StringWriter();
                    await statements.RenderStatementsAsync(bodyWriter, encoder, context);
                    var body = bodyWriter.ToString();

                    var result = reg.ScriptBlock.InvokeReturnAsIs(value, body);
                    var text = result?.ToString() ?? string.Empty;
                    writer.Write(text);
                    return Completion.Normal;
                });
                break;

            default:
                throw new ArgumentOutOfRangeException(nameof(reg), $"Unsupported block type: {reg.Type}");
        }
    }
}
