BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Register-LiquidBlock' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Register-LiquidBlock' {
        It 'Empty: block wraps content' {
            Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
                param($body)
                "<div class='card'>$body</div>"
            }

            $result = Format-LiquidString -Source '{% card %}Hello{% endcard %}' -Model @{}
            $result | Should -BeExactly "<div class='card'>Hello</div>"
        }

        It 'Identifier: block with identifier' {
            Register-LiquidBlock -Name 'tag' -Type Identifier -ScriptBlock {
                param($identifier, $body)
                "<$identifier>$body</$identifier>"
            }

            $result = Format-LiquidString -Source '{% tag span %}Bold{% endtag %}' -Model @{}
            $result | Should -BeExactly '<span>Bold</span>'
        }

        It 'Expression: block with expression (repeat)' {
            Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
                param($value, $body)
                $body * [int]$value
            }

            $result = Format-LiquidString -Source '{% repeat 3 %}Hi{% endrepeat %}' -Model @{}
            $result | Should -BeExactly 'HiHiHi'
        }
    }
}
