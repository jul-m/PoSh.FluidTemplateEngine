BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Format-LiquidString' {
	BeforeEach {
		Set-FluidModuleConfig -Reset
	}

	Context 'Format-LiquidString/ParameterSet=Default' {
		It 'Renders variables' {
			$result = Format-LiquidString -Source 'Hello {{ name }}' -Model @{ name = 'Alice' }
			$result | Should -BeExactly 'Hello Alice'
		}
	}

	Context 'Format-LiquidString/ParameterSet=HtmlEncoded' {
		It 'Encodes output when requested' {
			$result = Format-LiquidString -Source '{{ value }}' -Model @{ value = '<tag>' } -HtmlEncode
			$result | Should -BeExactly '&lt;tag&gt;'
		}
	}

	Context 'Format-LiquidString/ParameterSet=NoEncoding' {
		It 'Does not encode output with NoEncoding parameter (backward compatibility)' {
			$result = Format-LiquidString -Source '{{ value }}' -Model @{ value = '<tag>' } -NoEncoding
			$result | Should -BeExactly '<tag>'
		}
	}
}
