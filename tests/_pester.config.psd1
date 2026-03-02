<#
	Pester configuration file for this project.

	Values of `Run` and `TestResult` sections are used by `_tests.tools.ps1`, please check before changing them.

	Other sections, like `Should`, `Debug` and `Output` are used by tests and can be overridden with `-PesterConfig`
	parameter of `./run.ps1 -Mode Tests`.

	For get all more information for available options, you can run: `Get-Help about_PesterConfiguration`

	Path are relative to the root of the repository.
#>
@{
	# Default configuration for `_pwsh.tests.tools.ps1`, not used by Pester directly
	TestsToolsDefaultConfig = @{
		# Path to the built module .psd1 file, used for tests initialization.
		ModulePSD1Path = './out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
	}

	Run = @{
		Path = './tests'	# Paths or files to run tests from.
		Exit = $false		# Exit with non-zero exit code when the test run fails.
		PassThru = $true	# Return result object to the pipeline after finishing the test run.
	}

	TestResult = @{
		Enabled = $true				# Enable TestResult.
		OutputFormat = 'NUnitXml'	# Format to use for test result report (NUnitXml, NUnit2.5, NUnit3 or JUnitXml)
		OutputPath = './out/tests/test-results.xml' # Last test result path.
		# Result will copied with date-time suffix after each run.
	}

	Should = @{
		ErrorAction = 'Continue'	# Controls if Should throws on error.
	}

	Debug = @{
		WriteDebugMessages = $true	# Write Debug messages to screen.
	}

	Output = @{
		Verbosity = 'Normal'				# The verbosity of output (None, Normal, Detailed and Diagnostic).
		StackTraceVerbosity = 'FirstLine'	# The verbosity of stacktrace output (None, FirstLine, Filtered and Full).
	}
}
