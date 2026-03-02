BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Register-FluidType' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Register-FluidType/ParameterSet=ByType' {
        It 'Accepts a type parameter' {
            Register-FluidType -Type ([System.String])
            $true | Should -BeTrue
        }
    }

    Context 'Register-FluidType/ParameterSet=ByName' {
        It 'Accepts a type name string' {
            Register-FluidType -TypeName 'System.String'
            $true | Should -BeTrue
        }
    }
}
