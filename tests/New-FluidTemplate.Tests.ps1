BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet New-FluidTemplate' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'New-FluidTemplate' {
        It 'Creates a template that can be invoked via pipeline' {
            $tpl = New-FluidTemplate -Source 'Hi {{ name }}'
            $result = $tpl | Invoke-FluidTemplate -Model @{ name = 'Bob' }
            $result | Should -BeExactly 'Hi Bob'
        }
    }
}
