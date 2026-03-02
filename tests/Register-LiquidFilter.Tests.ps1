BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Register-LiquidFilter' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Register-LiquidFilter' {
        It 'Registers a ScriptBlock filter' {
            Register-LiquidFilter -Name 'shout' -ScriptBlock {
                param($input)
                $input.ToString().ToUpperInvariant()
            }

            $result = Format-LiquidString -Source "{{ name | shout }}" -Model @{ name = 'hello' }
            $result | Should -BeExactly 'HELLO'
        }
    }
}
