BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Set-FluidModuleConfig' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Set-FluidModuleConfig' {
        It 'StrictVariables throws on missing variable' {
            Set-FluidModuleConfig -StrictVariables
            { Format-LiquidString -Source 'Hello {{ missing }}' -Model @{ } -ErrorAction Stop } | Should -Throw
            Set-FluidModuleConfig -Reset
        }

        It 'StrictFilters throws on unknown filter (including in include)' {
            $root = Join-Path $TestDrive 'tpl-strict'
            New-Item -ItemType Directory -Path $root -Force | Out-Null

            Set-Content -Path (Join-Path $root 'partial.liquid') -Value "{{ 'hello' | unknown }}" -NoNewline
            Set-Content -Path (Join-Path $root 'main.liquid') -Value "{% include 'partial' %}" -NoNewline

            Set-FluidModuleConfig -StrictFilters
            { Invoke-FluidFile -Path (Join-Path $root 'main.liquid') -Model @{ } -TemplateRoot $root -ErrorAction Stop } | Should -Throw
            Set-FluidModuleConfig -Reset
        }
    }
}
