BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Register-LiquidTag' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Register-LiquidTag' {
        It 'Empty: tag without parameter' {
            Register-LiquidTag -Name 'greet' -Type Empty -ScriptBlock { 'Hello World' }

            $result = Format-LiquidString -Source '{% greet %}' -Model @{}
            $result | Should -BeExactly 'Hello World'
        }

        It 'Identifier: tag with identifier parameter' {
            Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
                param($identifier)
                "Hello $identifier"
            }

            $result = Format-LiquidString -Source '{% hello you %}' -Model @{}
            $result | Should -BeExactly 'Hello you'
        }

        It 'Expression: tag with expression parameter' {
            Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
                param($value)
                "[$value]"
            }

            $result = Format-LiquidString -Source "{% echo 'test' %}" -Model @{}
            $result | Should -BeExactly '[test]'
        }
    }
}
