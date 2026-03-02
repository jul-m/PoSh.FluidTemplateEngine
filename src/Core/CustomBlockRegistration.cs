using System.Management.Automation;

namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// Stores a custom Liquid block registration.
/// </summary>
internal sealed record CustomBlockRegistration(string Name, LiquidTagType Type, ScriptBlock ScriptBlock);
