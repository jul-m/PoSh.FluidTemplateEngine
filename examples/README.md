# PoSh.FluidTemplateEngine — Examples

These scripts use the module packaged into `../out/publish/PoSh.FluidTemplateEngine/`.

## Prerequisites

Build the module first:

```powershell
pwsh -NonInteractive ../run.ps1 -Mode Package
```

## Running Examples

```powershell
pwsh -NoProfile -File ./01-basic.ps1
pwsh -NoProfile -File ./02-include.ps1
pwsh -NoProfile -File ./03-strict.ps1
pwsh -NoProfile -File ./04-custom-filter.ps1
pwsh -NoProfile -File ./05-custom-tags-blocks.ps1
```

## What Each Example Demonstrates

| Script | Description |
|--------|-------------|
| `01-basic.ps1` | Basic rendering with `Format-LiquidString` and `New-FluidTemplate` / `Invoke-FluidTemplate` |
| `02-include.ps1` | File-based rendering with `{% include %}` support via `Invoke-FluidFile` |
| `03-strict.ps1` | Strict variables and strict filters modes |
| `04-custom-filter.ps1` | Registering and using custom Liquid filters |
| `05-custom-tags-blocks.ps1` | Registering custom tags and blocks |
