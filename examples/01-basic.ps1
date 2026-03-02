$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
Import-Module $modulePath -Force

Set-FluidModuleConfig -Reset

Write-Host "== Format-LiquidString ==" -ForegroundColor Cyan
Format-LiquidString -Source 'Hello {{ name }}' -Model @{ name = 'Alice' } | Write-Host

Write-Host "== New-FluidTemplate | Invoke-FluidTemplate ==" -ForegroundColor Cyan
$tpl = New-FluidTemplate -Source 'Hi {{ name }}'
$tpl | Invoke-FluidTemplate -Model @{ name = 'Bob' } | Write-Host
