$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
Import-Module $modulePath -Force

Set-FluidModuleConfig -Reset

Register-LiquidFilter -Name 'shout' -ScriptBlock {
    param($input)
    $input.ToString().ToUpperInvariant()
}

Write-Host "== Custom filter ==" -ForegroundColor Cyan
Format-LiquidString -Source "{{ name | shout }}" -Model @{ name = 'hello' } | Write-Host
