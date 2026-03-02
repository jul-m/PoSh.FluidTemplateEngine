BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Invoke-FluidFile' {
	BeforeEach {
		Set-FluidModuleConfig -Reset
	}

	Context 'Invoke-FluidFile/ParameterSet=Default' {
		It 'Can include partials from TemplateRoot' {
			$root = Join-Path $TestDrive 'tpl'
			New-Item -ItemType Directory -Path $root -Force | Out-Null

			Set-Content -Path (Join-Path $root 'partial.liquid') -Value 'partial={{ value }}' -NoNewline
			Set-Content -Path (Join-Path $root 'main.liquid') -Value "start:{% include 'partial' %}:end" -NoNewline

			$result = Invoke-FluidFile -Path (Join-Path $root 'main.liquid') -Model @{ value = 'X' } -TemplateRoot $root
			$result | Should -BeExactly 'start:partial=X:end'
		}
	}

	Context 'Invoke-FluidFile/ParameterSet=HtmlEncoded' {
		It 'Encodes output when requested' {
			$root = Join-Path $TestDrive 'tpl_encoded'
			New-Item -ItemType Directory -Path $root -Force | Out-Null
			Set-Content -Path (Join-Path $root 'test.liquid') -Value '{{ value }}' -NoNewline

			$result = Invoke-FluidFile -Path (Join-Path $root 'test.liquid') -Model @{ value = '<tag>' } -HtmlEncode
			$result | Should -BeExactly '&lt;tag&gt;'
		}
	}

	Context 'Invoke-FluidFile/ParameterSet=NoEncoding' {
		It 'Does not encode output with NoEncoding parameter (backward compatibility)' {
			$root = Join-Path $TestDrive 'tpl_noenc'
			New-Item -ItemType Directory -Path $root -Force | Out-Null
			Set-Content -Path (Join-Path $root 'test.liquid') -Value '{{ value }}' -NoNewline

			$result = Invoke-FluidFile -Path (Join-Path $root 'test.liquid') -Model @{ value = '<tag>' } -NoEncoding
			$result | Should -BeExactly '<tag>'
		}
	}
}
