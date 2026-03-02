BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Register-LiquidOperator' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Register-LiquidOperator' {
        It 'Registers a custom binary operator' {
            Register-LiquidOperator -Name 'xor' -ScriptBlock {
                param($left, $right)
                [bool]$left -xor [bool]$right
            }

            $result = Format-LiquidString -Source '{% if true xor false %}Yes{% endif %}' -Model @{}
            $result | Should -BeExactly 'Yes'
        }

        It 'Custom operator evaluates to false correctly' {
            Register-LiquidOperator -Name 'xor' -ScriptBlock {
                param($left, $right)
                [bool]$left -xor [bool]$right
            }

            $result = Format-LiquidString -Source '{% if true xor true %}Yes{% else %}No{% endif %}' -Model @{}
            $result | Should -BeExactly 'No'
        }
    }
}
