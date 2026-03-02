$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
Import-Module $modulePath -Force

Write-Host "== StrictVariables ==" -ForegroundColor Cyan
Set-FluidModuleConfig -Reset
Set-FluidModuleConfig -StrictVariables

try {
    Format-LiquidString -Source 'Hello {{ missing }}' -Model @{ }
}
catch {
    Write-Host "OK: erreur attendue: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "== StrictFilters ==" -ForegroundColor Cyan
Set-FluidModuleConfig -Reset
Set-FluidModuleConfig -StrictFilters

try {
    Format-LiquidString -Source "{{ 'hello' | unknown }}" -Model @{ }
}
catch {
    Write-Host "OK: erreur attendue: $($_.Exception.Message)" -ForegroundColor Yellow
}

Set-FluidModuleConfig -Reset
