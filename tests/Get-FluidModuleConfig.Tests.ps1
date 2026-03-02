BeforeAll {
    if (-not (Get-Command Initialize-TestEnvironment -ErrorAction SilentlyContinue)) {
        . "$PSScriptRoot/_pwsh.tests.tools.ps1"
    }
    Initialize-TestEnvironment -SkipIfInitialized
}

Describe 'Cmdlet Get-FluidModuleConfig' {
	BeforeEach {
		Set-FluidModuleConfig -Reset
	}

	Context 'Get-FluidModuleConfig' {
		It 'Returns the current configuration' {
			Set-FluidModuleConfig -StrictVariables
			$config = Get-FluidModuleConfig
			$config.StrictVariables | Should -BeTrue
		}

		It 'Returns default configuration when reset' {
			$config = Get-FluidModuleConfig
			$config.StrictVariables | Should -BeFalse
			$config.StrictFilters | Should -BeFalse
		}
	}
}
