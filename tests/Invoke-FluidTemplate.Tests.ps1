BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Invoke-FluidTemplate' {
    BeforeEach {
        Set-FluidModuleConfig -Reset
    }

    Context 'Invoke-FluidTemplate/ParameterSet=Default' {
        It 'Works via pipeline' {
            $tpl = New-FluidTemplate -Source 'Hi {{ name }}'
            $result = $tpl | Invoke-FluidTemplate -Model @{ name = 'Bob' }
            $result | Should -BeExactly 'Hi Bob'
        }
    }

    Context 'Invoke-FluidTemplate/ParameterSet=HtmlEncoded' {
        It 'Encodes output when requested' {
            $tpl = New-FluidTemplate -Source '{{ value }}'
            $result = $tpl | Invoke-FluidTemplate -Model @{ value = '<tag>' } -HtmlEncode
            $result | Should -BeExactly '&lt;tag&gt;'
        }
    }

    Context 'Invoke-FluidTemplate/ParameterSet=NoEncoding' {
        It 'Does not encode output with NoEncoding parameter (backward compatibility)' {
            $tpl = New-FluidTemplate -Source '{{ value }}'
            $result = $tpl | Invoke-FluidTemplate -Model @{ value = '<tag>' } -NoEncoding
            $result | Should -BeExactly '<tag>'
        }
    }
}
