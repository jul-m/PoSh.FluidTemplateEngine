using System.Management.Automation;
using Fluid.Ast;
using Fluid.Values;

namespace PoSh.FluidTemplateEngine.Core;

/// <summary>
/// A <see cref="BinaryExpression"/> backed by a PowerShell <see cref="ScriptBlock"/>.
/// The ScriptBlock receives the left and right values and must return a boolean.
/// </summary>
internal sealed class ScriptBlockBinaryExpression(
    Expression left, Expression right, ScriptBlock scriptBlock
) : BinaryExpression(left, right)
{
    private readonly ScriptBlock _scriptBlock = scriptBlock ?? throw new ArgumentNullException(nameof(scriptBlock));

    public override async ValueTask<FluidValue> EvaluateAsync(Fluid.TemplateContext context)
    {
        var leftValue = await Left.EvaluateAsync(context);
        var rightValue = await Right.EvaluateAsync(context);

        var leftObj = leftValue.ToObjectValue();
        var rightObj = rightValue.ToObjectValue();

        var result = _scriptBlock.InvokeReturnAsIs(leftObj, rightObj);
        var boolResult = LanguagePrimitives.IsTrue(result);

        return BooleanValue.Create(boolResult);
    }
}
