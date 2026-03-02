$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
Import-Module $modulePath -Force

$templates = Join-Path $PSScriptRoot 'templates'

Set-FluidModuleConfig -Reset
Set-FluidModuleConfig -TemplateRoot $templates

Write-Host "== Invoke-FluidFile + include ==" -ForegroundColor Cyan
Invoke-FluidFile -Path (Join-Path $templates 'main.liquid') -Model @{ value = 'X' } | Write-Host
