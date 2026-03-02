using System.Collections;
using System.Management.Automation;

namespace PoSh.FluidTemplateEngine.Core;

internal static class PsModelConverter
{
    public static IReadOnlyDictionary<string, object?> ToDictionary(object? model)
    {
        if (model == null)
        {
            return new Dictionary<string, object?>();
        }

        // PowerShell often wraps values in PSObject. Prefer the underlying BaseObject
        // for scalars and dictionaries to preserve expected Liquid semantics.
        if (model is PSObject psObjectRoot)
        {
            var baseObject = psObjectRoot.BaseObject;
            if (baseObject is null)
            {
                return new Dictionary<string, object?>();
            }

            // If it's a scalar, keep it as-is (do not expand properties like Length).
            if (baseObject is string || baseObject.GetType().IsValueType)
            {
                return new Dictionary<string, object?> { ["value"] = baseObject };
            }

            // Prefer dictionary conversion when PS wraps a Hashtable/Dictionary.
            if (baseObject is IDictionary dictBase)
            {
                return IDictionaryToDictionary(dictBase);
            }

            // Otherwise, keep the PSObject properties (for PSCustomObject-style models).
            model = psObjectRoot;
        }

        if (model is IReadOnlyDictionary<string, object?> roDict)
        {
            return roDict;
        }

        if (model is IDictionary dict)
        {
            return IDictionaryToDictionary(dict);
        }

        if (model is PSObject psObject)
        {
            return PSObjectToDictionary(psObject);
        }

        return new Dictionary<string, object?> { ["value"] = model };
    }

    private static IReadOnlyDictionary<string, object?> PSObjectToDictionary(PSObject psObject)
    {
        var result = new Dictionary<string, object?>(StringComparer.Ordinal);
        foreach (var prop in psObject.Properties)
        {
            result[prop.Name] = NormalizeValue(prop.Value);
        }
        return result;
    }

    private static IReadOnlyDictionary<string, object?> IDictionaryToDictionary(IDictionary dict)
    {
        var result = new Dictionary<string, object?>(StringComparer.Ordinal);
        foreach (DictionaryEntry entry in dict)
        {
            var key = entry.Key?.ToString() ?? "";
            if (string.IsNullOrWhiteSpace(key))
            {
                continue;
            }

            result[key] = NormalizeValue(entry.Value);
        }
        return result;
    }

    private static object? NormalizeValue(object? value)
    {
        if (value == null)
        {
            return null;
        }

        if (value is PSObject psObject)
        {
            var baseObject = psObject.BaseObject;
            if (baseObject is null)
            {
                return null;
            }

            if (baseObject is string || baseObject.GetType().IsValueType)
            {
                return baseObject;
            }

            if (baseObject is IDictionary dictBase)
            {
                return IDictionaryToDictionary(dictBase);
            }

            if (baseObject is IEnumerable enumerableBase and not string)
            {
                var baseList = new List<object?>();
                foreach (var item in enumerableBase)
                {
                    baseList.Add(NormalizeValue(item));
                }
                return baseList;
            }

            // PSCustomObject and complex PSObjects: keep note properties.
            return PSObjectToDictionary(psObject);
        }

        if (value is IDictionary dict)
        {
            return IDictionaryToDictionary(dict);
        }

        if (value is IEnumerable enumerable and not string)
        {
            var list = new List<object?>();
            foreach (var item in enumerable)
            {
                list.Add(NormalizeValue(item));
            }
            return list;
        }

        return value;
    }
}
