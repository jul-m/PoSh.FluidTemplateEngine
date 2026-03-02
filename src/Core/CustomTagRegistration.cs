using System.Management.Automation;

namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// Stores a custom Liquid tag registration.
/// </summary>
internal sealed record CustomTagRegistration(string Name, LiquidTagType Type, ScriptBlock ScriptBlock);
