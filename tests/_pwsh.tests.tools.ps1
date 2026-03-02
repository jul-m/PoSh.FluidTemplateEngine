<#
.SYNOPSIS
Generic Pester test utilities for binary PowerShell modules.

.DESCRIPTION
Provides common test helpers: test environnement configuration, run tests in dedicated PowerShell job,
temp file management, ParameterSet coverage reporting and custom should operators.

Designed to be dot-sourced from a consumer project's test runner script (e.g. `run.ps1`), and used in Pester tests.

.LINK
Source: https://github.com/jul-m/Dev.Tools/tree/main/PesterTestTools/_pwsh.tests.tools.ps1

.LINK
Documentation: https://github.com/jul-m/Dev.Tools/tree/main/PesterTestTools/README.md

.NOTES
Version: 0.1.0 - 01/03/2026
#>


##################################################
# INIT & CONFIG
##################################################

Set-StrictMode -Off

$global:ProgressPreference = 'SilentlyContinue'	# Suppress progress bars during tests
$global:ConfirmPreference = 'None'				# Disable confirmation prompts during tests

try {
	Import-Module Pester -ErrorAction Stop
}
catch {
	if ($_.FullyQualifiedErrorId -like "Modules_ModuleNotFound*") {
		Write-Error "Module Pester not found. Use 'Install-Module Pester' to install it from the PowerShell Gallery."
	} else {
		Write-Error "Failed to import module Pester: $($_.Exception.Message)"
	}
}


##################################################
# TEST ENVIRONMENT INIT & CONFIG FUNCTIONS
##################################################

function Initialize-TestEnvironment {
	<#
	.SYNOPSIS
	Initializes the test environment by setting up global configuration and importing the module under test.
	#>
	[CmdletBinding()]
	param(
		# Path to PSD1 file of builded module to import for testing.
		# Default to `$ProjectRoot/out/publish/ModuleName/ModuleName.psd1`.
		[Parameter()]	[string]$ModulePSD1Path,

		# Root path of the project (where src/, tests/, etc. are located). Default to parent of the current script.
		[Parameter()]	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,

		# Path to PSD1 file of Pester base configuration for the project tests.
		# Default to `_pester.config.psd1` under the current script.
		[Parameter()]	[string]$PesterConfigPath = (Join-Path $PSScriptRoot '_pester.config.psd1'),

		# Skip initialization if already done (e.g. when calling `Initialize-TestEnvironment` in each test script).
		[Parameter()]	[switch]$SkipIfInitialized
	)

	if ($SkipIfInitialized -and $global:_PesterTestToolsConfig -and $global:_PesterTestToolsConfig.Initialized) {
		Write-Verbose "Test environment already initialized. Skipping initialization."
		return
	}

	try {
		$pesterBaseConfigPsd1 = Import-PowerShellDataFile -Path $PesterConfigPath -ErrorAction Stop

		if (!$pesterBaseConfigPsd1.TestResult.OutputPath) {
			# If OutputPath is not set in the config, set a default one to ./out/tests/test-results.xml
			$pesterBaseConfigPsd1.TestResult.OutputPath = "$ProjectRoot/out/tests/test-results.xml"
		}
		if (!$pesterBaseConfigPsd1.TestResult.OutputFormat) {
			# If OutputFormat is not set in PSD1, set to NUnitXml (for coverage report generation compatibility)
			$pesterBaseConfigPsd1.TestResult.OutputFormat = 'NUnitXml'
		}

		$pesterBaseConfig = [PesterConfiguration]::new($pesterBaseConfigPsd1)
	}
	catch {
		throw "Unable to load Pester configuration from '$PesterConfigPath'. Details: $($_.Exception.Message)"
	}

	if (!$ModulePSD1Path) {
		$ModulePSD1Path = $pesterBaseConfigPsd1.TestsToolsDefaultConfig.ModulePSD1Path
	}

	# Import the module under test (binary module is expected to be packaged)
	if (-not (Test-Path $ModulePSD1Path)) {
		throw "Packaged module manifest not found: '$ModulePSD1Path'. " + `
			"Please check if module is built and the path is correct."
	}

	try {
		$module = Import-Module $ModulePSD1Path -Force -ErrorAction Stop -PassThru
		$global:_PesterTestToolsConfig = @{
			ModuleName				= $module.Name
			ProjectRoot				= $ProjectRoot
			PSModuleInfo			= $module
			PesterBaseConfig		= $pesterBaseConfig
			OutputBasePath			= (Split-Path $pesterBaseConfig.TestResult.OutputPath.Value -Parent)
			Initialized				= $true
			DefaultTempPrefix		= 'tests'
		}
		Write-Host "Module '$($module.Name)' imported successfully for testing from '$ModulePSD1Path'."
	}
	catch {
		throw "Unable to import module from '$ModulePSD1Path'. Details: $($_.Exception.Message)"
	}
}

function Get-PesterTestToolsConfig {
	<#
	.SYNOPSIS
	Returns the current PesterTestTools configuration hashtable, or error if not initialized.
	#>
	[CmdletBinding()]
	param()
	if (-not $global:_PesterTestToolsConfig -or -not $global:_PesterTestToolsConfig.Initialized) {
		throw 'Test environment not initialized. Please call `Initialize-TestEnvironment` first.'
	}
	return $global:_PesterTestToolsConfig
}


##################################################
# RUN TESTS FUNCTIONS
##################################################

function Invoke-TestsInJob {
	<#
	.SYNOPSIS
	Runs tests in a dedicated PowerShell job to avoid DLL caching issues.

	.DESCRIPTION
	Launches test execution in an isolated PowerShell job process. This prevents issues when a previous
	version of a DLL has been imported in the current session. Test output is streamed in real-time as
	the job executes.

	.EXAMPLE
	Invoke-TestsInJob -ProjectRoot $ProjectRoot -ModulePSD1Path $BuildedPSD1Path -Verbosity 'Detailed' -CoverageReport
	# Runs tests in a dedicated job with detailed output and generates coverage report.
	#>
	[CmdletBinding()]
	param(
		# Path to PSD1 file of builded module to import for testing.
		# Default to `$ProjectRoot/out/publish/ModuleName/ModuleName.psd1`.
		[Parameter()]	[string]$ModulePSD1Path,

		# Root path of the project (where src/, tests/, etc. are located). Default to parent of the current script.
		[Parameter()]	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,

		# The verbosity of output for tests ('None', 'Normal', 'Detailed', 'Diagnostic').
		[Parameter()][ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic', '')]
		[string]$Verbosity = '',

		# The verbosity of stacktrace output ('None', 'FirstLine', 'Filtered', 'Full').
		[Parameter()][ValidateSet('None', 'FirstLine', 'Filtered', 'Full', '')]
		[string]$StackTraceVerbosity = '',

		# Override Pester configuration (advanced usage, hashtable).
		[Parameter()]	[hashtable]$PesterConfig,

		# Whether to generate coverage report after tests complete.
		[Parameter()]	[switch]$CoverageReport
	)

	$testScriptBlock = {
		param(
			[string]$TestsRoot,
			[string]$ProjectRoot,
			[string]$ModulePSD1Path,
			[string]$Verbosity,
			[string]$StackTraceVerbosity,
			[hashtable]$PesterConfig,
			[bool]$GenerateCoverageReport
		)

		# Load test tools functions in the job
		. "$TestsRoot/_pwsh.tests.tools.ps1"

		# Init test environment and run tests
		Initialize-TestEnvironment -ModulePSD1Path $ModulePSD1Path -ProjectRoot $ProjectRoot

		Test-PowerShellModule `
			-Verbosity $Verbosity `
			-StackTraceVerbosity $StackTraceVerbosity `
			-PesterConfig $PesterConfig `
			-CoverageReport:$GenerateCoverageReport
	}

	Write-Host "Starting tests in a dedicated PowerShell job..." -ForegroundColor Cyan
	$job = Start-Job -ScriptBlock $testScriptBlock `
		-ArgumentList @(
			$PSScriptRoot,
			$ProjectRoot,
			$ModulePSD1Path,
			$Verbosity,
			$StackTraceVerbosity,
			$PesterConfig,
			$CoverageReport.IsPresent
		)

	# Stream output in real-time as the job runs
	while ($job.State -eq 'Running') {
		Receive-Job -Job $job
		Start-Sleep -Milliseconds 250
	}

	# Get any remaining output after job completion
	Receive-Job -Job $job

	# Check job result and clean up
	$jobSucceeded = $job.State -eq 'Completed'
	Remove-Job -Job $job

	if (-not $jobSucceeded) {
		throw "Tests job failed with state: $($job.State)"
	}
}

function Test-PowerShellModule {
	[CmdletBinding()]
	param(
		# The verbosity of output, options are: 'None', 'Normal', 'Detailed' and 'Diagnostic'.
		# If not specified, value defined in `_pester.config.psd1` will be used.
		[Parameter()][ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic', '')]
		[string]$Verbosity,

		# The verbosity of stacktrace output, options are: 'None', 'FirstLine', 'Filtered' and 'Full'.
		# If not specified, value defined in `_pester.config.psd1` will be used.
		[Parameter()][ValidateSet('None', 'FirstLine', 'Filtered', 'Full', '')]
		[string]$StackTraceVerbosity,

		# Override Pester configuration (advanced usage)
		[Parameter()]	[hashtable]$PesterConfig,

		# Run Coverage report generation after tests
		[Parameter()]	[switch]$CoverageReport
	)

	# Load test environnment with config or throw if not initialized
	$cfg = Get-PesterTestToolsConfig

	# Merge overrides if present
	if ($PesterConfig) {
		$finalConfig = [PesterConfiguration]::Merge($cfg.PesterBaseConfig, $PesterConfig)
		Write-Host "Merged Pester configuration with overrides from -PesterConfig parameter."
	} else {
		Write-Host "No Pester configuration overrides provided. Using default."
		$finalConfig = $cfg.PesterBaseConfig
	}

	if ($Verbosity) {
		$finalConfig.Output.Verbosity = $Verbosity
	}
	if ($StackTraceVerbosity) {
		$finalConfig.Output.StackTraceVerbosity = $StackTraceVerbosity
	}

	$result = Invoke-Pester -Configuration $finalConfig

	if ($CoverageReport) {
		try {
			$covReportResult = New-TestsCoverageReport -PesterConfig $finalConfig
			Write-Host "Coverage report generated: $($covReportResult.ReportMdPath)"
		}
		catch {
			Write-Warning "Failed generating coverage report: $($_.Exception.Message)"
		}
	}

	if ($result.FailedCount -eq 0) {
		Write-Host "✅ All tests passed! ✅"
	} else {
		Write-Host "❌ $($result.FailedCount) test(s) failed" -ForegroundColor Red
		Write-Host "✅ $($result.PassedCount) test(s) passed" -ForegroundColor Green
		Write-Host "⏭️  $($result.SkippedCount) test(s) skipped" -ForegroundColor Yellow
		Write-Error "Some tests failed. See details above."
	}

	# Copy test result with date-time suffix for historical tracking
	Copy-Item -Path $finalConfig.TestResult.OutputPath.Value `
		-Destination (Join-Path $cfg.OutputBasePath ("test-results_{0:yyyyMMdd_HHmmss}.xml" -f (Get-Date)))
}


##################################################
# TEMP FILE UTILITIES
##################################################

function Get-TestsTempRoot {
	<#
	.SYNOPSIS
	Returns the temp root (Pester TestDrive if available, otherwise system temp).
	#>
	[CmdletBinding()]
	param()

	$testDriveVar = Get-Variable -Name TestDrive -Scope Global -ErrorAction SilentlyContinue
	if ($testDriveVar -and $testDriveVar.Value) {
		return [string]$testDriveVar.Value
	}

	return [System.IO.Path]::GetTempPath()
}

function New-TestsTempDirectory {
	<#
		.SYNOPSIS
		Creates a uniquely-named temp directory.
	#>
	[CmdletBinding()]
	param(
		# Optional prefix for the directory name (default: "tests"). A GUID is appended to ensure uniqueness.
		[Parameter()]	[string]$Prefix
	)

	if (-not $Prefix) { $Prefix = (Get-PesterTestToolsConfig).DefaultTempPrefix }

	$root = Get-TestsTempRoot
	$path = Join-Path $root ("{0}_{1}" -f $Prefix, ([guid]::NewGuid().ToString('N')))
	return (New-Item -ItemType Directory -Path $path -Force)
}

function New-TestsTempFile {
	<#
	.SYNOPSIS
	Creates a uniquely-named temp file with the given content.
	#>
	[CmdletBinding()]
	param(
		# Content to write in the file.
		[Parameter(Mandatory)]	[string]$Content,

		# Optional file extension. Default to `.txt`.
		[Parameter()]	[string]$Extension = '.txt',

		# Optional prefix for the file name (default: "tmpfile"). A GUID is appended to ensure uniqueness.
		[Parameter()]	[string]$Prefix = 'tmpfile',

		# Optional directory to create the file in (default: temp root).
		[Parameter()]	[string]$Directory
	)

	if (-not $Directory) {
		$Directory = Get-TestsTempRoot
	}

	if ($Extension -and -not $Extension.StartsWith('.')) {
		$Extension = ".$Extension"
	}

	$fileName = "{0}_{1}{2}" -f $Prefix, ([guid]::NewGuid().ToString('N')), $Extension
	$filePath = Join-Path $Directory $fileName

	$file = New-Item -ItemType File -Path $filePath -Force
	Set-Content -Path $file.FullName -Value $Content
	return $file
}

function Remove-TestsItemSafe {
	<#
	.SYNOPSIS
	Safely removes files or directories (ignores errors).
	#>
	[CmdletBinding()]
	param(
		# Paths to items to remove.
		[Parameter(Mandatory, ValueFromPipeline)][SupportsWildcards()]	[string[]]$Path
	)

	process {
		foreach ($p in $Path) {
			if ([string]::IsNullOrWhiteSpace($p)) { continue }
			Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
		}
	}
}


##################################################
# COVERAGE REPORT
##################################################

function New-TestsCoverageReport {
	<#
	.SYNOPSIS
	Generates a ParameterSet coverage report from Pester NUnitXml test results.
	#>
	[CmdletBinding()]
	param(
		# Pester configuration used for the test to generate the report from.
		# If not specified, configuration loaded from `_pester.config.psd1` file will be used.
		[Parameter()]	[PesterConfiguration]$PesterConfig
	)

	$cfg = Get-PesterTestToolsConfig

	if (!$cfg.PesterBaseConfig.TestResult.Enabled.Value -or
		$cfg.PesterBaseConfig.TestResult.OutputFormat.Value -ne 'NUnitXml'
	) {
		throw "TestResult must be enabled AND set to NUnitXml format in Pester configuration for coverage report " + `
			"generation. Current config: Enabled=$($cfg.PesterBaseConfig.TestResult.Enabled.Value
			), OutputFormat=$($cfg.PesterBaseConfig.TestResult.OutputFormat.Value)"
	}

	$testResultsXmlPath = $cfg.PesterBaseConfig.TestResult.OutputPath.Value

	if (!(Test-Path -LiteralPath $testResultsXmlPath)) {
		throw "Test results XML file not found at expected path: '$testResultsXmlPath'. " + `
			"Please check if tests are already runned with correct Pester configuration and the path is correct."
	}

	$outputBasePath = $cfg.OutputBasePath
	$cmdletsParameterSetsJsonPath = Join-Path $outputBasePath 'cmdlets.parametersets.json'
	$reportMdPath = Join-Path $outputBasePath 'coverage-report.md'
	$summaryJsonPath = Join-Path $outputBasePath 'coverage-summary.json'

	$now = Get-Date

	# --------------------------
	# Generate cmdlets ParameterSets inventory
	# --------------------------
	$cmdletsInventory = $null
	$cmdletsInventory = @(
		Get-Command -Module $cfg.ModuleName -CommandType Cmdlet -ErrorAction Stop |
		Sort-Object Name |
		ForEach-Object {
			[pscustomobject]@{
				Name			 = $_.Name
				ParameterSets = @($_.ParameterSets | ForEach-Object Name | Sort-Object -Unique)
			}
		}
	)

	$cmdletsInventory |
		ConvertTo-Json -Depth 10 |
		Set-Content -LiteralPath $cmdletsParameterSetsJsonPath

	$cmdletNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	foreach ($c in @($cmdletsInventory)) {
		if ($c -and $c.Name) {
			$cmdletNames.Add([string]$c.Name) | Out-Null
		}
	}

	# --------------------------
	# Parse Pester NUnitXml test results (test-case level)
	# --------------------------
	$testResults = $null
	$cmdletsWithAnyTests = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	$parameterSetsCoveredByCmdlet =	@{} # cmdlet => HashSet[set]
	$cmdletTotals = @{}					# cmdlet => stats
	$cmdletParameterSetTotals = @{}		# cmdlet => (set => stats)
	$testResultSummary = $null

	function New-StatsObject() {
		return [pscustomobject]@{
			Total		  = 0
			Passed		 = 0
			Failed		 = 0
			Skipped		= 0
			Inconclusive = 0
			Other		  = 0
		}
	}

	function Add-Stats(
		[Parameter(Mandatory)][psobject]$Stats,
		[Parameter(Mandatory)][string]$Result
	) {
		$Stats.Total += 1
		switch -Regex ($Result) {
			'^Success$' { $Stats.Passed += 1; break }
			'^Failure$' { $Stats.Failed += 1; break }
			'^(Skipped|Ignored|NotRun)$' { $Stats.Skipped += 1; break }
			'^Inconclusive$' { $Stats.Inconclusive += 1; break }
			default { $Stats.Other += 1; break }
		}
	}

	function Get-TestNameMapping([Parameter(Mandatory)][string]$TestCaseName) {
		# Supported naming conventions (tests MUST be in a Context within Describe "Cmdlet <CmdletName>"):
		# - Describe "Cmdlet CmdletName" { Context "CmdletName [ comment]" { It ... } }
		# - Describe "Cmdlet CmdletName" { Context "CmdletName/ParameterSet=ParameterSetName [ comment]" { It ... } }
		# Pester NUnitXml test-case names look like: "<Describe>.<Context>.<It>"
		# Comments are separated from cmdlet/parameterset by a single space and are ignored in mapping.

		# Extract parts: Describe, Context, and It
		$parts = $TestCaseName -split '\.' | ForEach-Object { $_ }
		if ($parts.Count -lt 3) {
			return $null  # Invalid format, needs Describe.Context.It
		}

		$describePart = $parts[0]
		$contextPart = $parts[1]
		# $itPart = $parts[2] (not needed for mapping)

		# Validate Describe format: must be "Cmdlet <CmdletName>"
		$describeMatch = [regex]::Match($describePart, '^Cmdlet\s+(?<Cmdlet>.+)$')
		if (-not $describeMatch.Success) {
			return $null  # Invalid describe format
		}

		$describeCmdletName = $describeMatch.Groups['Cmdlet'].Value.Trim()

		# Pattern 1: Explicit ParameterSet using slash notation: CmdletName/ParameterSet=SetName [comment]
		$m = [regex]::Match($contextPart, '^(?<Cmdlet>\S+)/ParameterSet=(?<Set>\S+)')
		if ($m.Success) {
			$cmdletName = $m.Groups['Cmdlet'].Value.Trim()
			if ($cmdletName -ne $describeCmdletName) {
				return $null  # Mismatch between Describe and Context cmdlet name
			}
			$set = $m.Groups['Set'].Value.Trim()
			return [pscustomobject]@{ Cmdlet = $cmdletName; ParameterSet = $set }
		}

		# Pattern 2: Simple Context (single cmdlet name with optional comment): CmdletName [comment]
		$m = [regex]::Match($contextPart, '^(?<Cmdlet>\S+)(?:\s+.*)?$')
		if ($m.Success) {
			$cmdletName = $m.Groups['Cmdlet'].Value.Trim()
			if ($cmdletName -ne $describeCmdletName) {
				return $null  # Mismatch between Describe and Context cmdlet name
			}
			return [pscustomobject]@{ Cmdlet = $cmdletName; ParameterSet = $null }
		}

		return $null
	}

	if (Test-Path -LiteralPath $testResultsXmlPath) {
		[xml]$testResults = Get-Content -LiteralPath $testResultsXmlPath -Raw
		$root = $testResults.'test-results'

		$testResultSummary = [pscustomobject]@{
			Total		  = [int]$root.total
			Errors		 = [int]$root.errors
			Failures	  = [int]$root.failures
			Skipped		= [int]$root.skipped
			NotRun		 = [int]$root.'not-run'
			Inconclusive = [int]$root.inconclusive
			Date			= [string]$root.date
			Time			= [string]$root.time
		}

		$allCases = $testResults.SelectNodes('//test-case')
		foreach ($case in @($allCases)) {
			$caseName = [string]$case.name
			if ([string]::IsNullOrWhiteSpace($caseName)) { continue }

			$mapping = Get-TestNameMapping -TestCaseName $caseName
			if (-not $mapping) { continue }

			$cmdletName = [string]$mapping.Cmdlet
			if (-not $cmdletNames.Contains($cmdletName)) {
				continue
			}

			$cmdletsWithAnyTests.Add($cmdletName) | Out-Null

			if (-not $cmdletTotals.ContainsKey($cmdletName)) {
				$cmdletTotals[$cmdletName] = New-StatsObject
			}

			$result = [string]$case.result
			if ([string]::IsNullOrWhiteSpace($result)) { $result = 'Unknown' }
			Add-Stats -Stats $cmdletTotals[$cmdletName] -Result $result

			$setName = $null
			if ($mapping.ParameterSet) {
				$setName = [string]$mapping.ParameterSet
			}

			if ($setName) {
				if (-not $parameterSetsCoveredByCmdlet.ContainsKey($cmdletName)) {
					$parameterSetsCoveredByCmdlet[$cmdletName] = [System.Collections.Generic.HashSet[string]]::new(
						[System.StringComparer]::OrdinalIgnoreCase)
				}
				$null = $parameterSetsCoveredByCmdlet[$cmdletName].Add($setName)
			}

			$setKey = if ($setName) { $setName } else { '__Cmdlet__' }
			if (-not $cmdletParameterSetTotals.ContainsKey($cmdletName)) {
				$cmdletParameterSetTotals[$cmdletName] = @{}
			}
			if (-not $cmdletParameterSetTotals[$cmdletName].ContainsKey($setKey)) {
				$cmdletParameterSetTotals[$cmdletName][$setKey] = New-StatsObject
			}
			Add-Stats -Stats $cmdletParameterSetTotals[$cmdletName][$setKey] -Result $result
		}
	}

	# --------------------------
	# ParameterSet coverage from out/tests data
	# --------------------------
	$parameterSetCoverageDetails = @()
	$expectedTotal = 0
	$coveredTotal = 0
	$missingTotal = 0

	foreach ($cmd in $cmdletsInventory) {
		$expected = @($cmd.ParameterSets)
		if (-not $expected) {
			$expected = @('__AllParameterSets')
		}

		$expectedNormalized = @($expected | ForEach-Object { [string]$_ } | Sort-Object -Unique)
		$coveredSets = @()
		$missingSets = @()
		$hasAnyTests = $cmdletsWithAnyTests.Contains([string]$cmd.Name)

		# Cmdlets sans ParameterSet explicite (fallback)
		if ($expectedNormalized.Count -eq 1 -and $expectedNormalized[0] -eq '__AllParameterSets') {
			$expectedTotal += 1
			if ($hasAnyTests) {
				$coveredTotal += 1
			}
			else {
				$missingTotal += 1
				$missingSets = @('__AllParameterSets')
			}
		}
		else {
			$expectedTotal += $expectedNormalized.Count
			$coveredHash = $null
			if ($parameterSetsCoveredByCmdlet.ContainsKey([string]$cmd.Name)) {
				$coveredHash = $parameterSetsCoveredByCmdlet[[string]$cmd.Name]
			}

			# Simple rule:
			# - Single ParameterSet expected: Describe "Cmdlet" is sufficient
			# - Multiple ParameterSets: need tests by set (Describe "Cmdlet Set")
			$singleSet = ($expectedNormalized.Count -eq 1)

			foreach ($setName in $expectedNormalized) {
				$covered = $false
				if ($coveredHash -and $coveredHash.Contains($setName)) {
					$covered = $true
				}
				elseif ($singleSet -and $hasAnyTests) {
					$covered = $true
				}

				if ($covered) {
					$coveredSets += $setName
					$coveredTotal += 1
				}
				else {
					$missingSets += $setName
					$missingTotal += 1
				}
			}
		}

		$parameterSetCoverageDetails += [pscustomobject]@{
			Name						= [string]$cmd.Name
			ExpectedParameterSets = $expectedNormalized
			CoveredParameterSets  = @($coveredSets | Sort-Object -Unique)
			MissingParameterSets  = @($missingSets | Sort-Object -Unique)
			HasAnyTests			  = [bool]$hasAnyTests
		}
	}

	if ($expectedTotal -gt 0) {
		$parameterSetCoveragePercent = [math]::Round(($coveredTotal * 100.0) / $expectedTotal, 2)
	} else {
		$parameterSetCoveragePercent = 0.0
	}

	# --------------------------
	# Write artifacts
	# --------------------------
	# Build per-cmdlet stats for summary (including per-ParameterSet)
	$cmdletsStats = @()
	foreach ($cmd in @($cmdletsInventory | Sort-Object Name)) {
		$cmdletName = [string]$cmd.Name
		$expectedSets = @($cmd.ParameterSets)
		if (-not $expectedSets) {
			$expectedSets = @('__AllParameterSets')
		}

		$cmdStats = $null
		if ($cmdletTotals.ContainsKey($cmdletName)) {
			$cmdStats = $cmdletTotals[$cmdletName]
		}
		else {
			$cmdStats = New-StatsObject
		}

		$setStats = @()
		if ($cmdletParameterSetTotals.ContainsKey($cmdletName)) {
			foreach ($kv in $cmdletParameterSetTotals[$cmdletName].GetEnumerator() | Sort-Object Name) {
				$setStats += [pscustomobject]@{
					Name  = [string]$kv.Key
					Stats = $kv.Value
				}
			}
		}

		$coverageDetail = $parameterSetCoverageDetails | Where-Object Name -EQ $cmdletName | Select-Object -First 1
		$cmdletsStats += [pscustomobject]@{
			Name						= $cmdletName
			ExpectedParameterSets = @($expectedSets | ForEach-Object { [string]$_ } | Sort-Object -Unique)
			CoveredParameterSets  = @($coverageDetail.CoveredParameterSets)
			MissingParameterSets  = @($coverageDetail.MissingParameterSets)
			HasAnyTests			  = [bool]$coverageDetail.HasAnyTests
			Totals					 = $cmdStats
			ByParameterSet		  = $setStats
		}
	}

	$summary = [pscustomobject]@{
		GeneratedAt				= $now.ToString('o')
		ModuleName				= $cfg.ModuleName
		OutTestsDir				= $outputBasePath
		TestResults				= $testResultSummary
		ReportMdPath			= $reportMdPath
		Cmdlets					= $cmdletsStats
		ParameterSetCoverage	= [pscustomobject]@{
			ExpectedTotal			= $expectedTotal
			CoveredTotal			= $coveredTotal
			MissingTotal			= $missingTotal
			Percent					= $parameterSetCoveragePercent
		}
	}

	$summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $summaryJsonPath

	$missingParameterSetsByCmdlet = @(
		$parameterSetCoverageDetails |
			Where-Object { $_.MissingParameterSets.Count -gt 0 } |
			Sort-Object Name
	)

	if ($missingParameterSetsByCmdlet.Count -gt 0) {
		$warningMsg = "Missing ParameterSets for $($missingParameterSetsByCmdlet.Count) cmdlet(s):"
		foreach ($c in $missingParameterSetsByCmdlet) {
			$missingList = ($c.MissingParameterSets -join ', ')
			$warningMsg += "`n  - $($c.Name): $missingList"
		}
		Write-Warning $warningMsg
	}

	function AddLine([System.Text.StringBuilder]$sb, [string]$line) {
		$null = $sb.AppendLine($line)
	}

	$md = New-Object System.Text.StringBuilder
	AddLine $md "# Coverage Report ($($cfg.ModuleName))"
	AddLine $md ''
	AddLine $md "Generated: $($now.ToString('yyyy-MM-dd HH:mm:ss'))"
	AddLine $md ''
	AddLine $md '## Pester Results (NUnitXml)'
	if ($testResultSummary) {
		AddLine $md "- Total: $($testResultSummary.Total)"
		AddLine $md "- Failures: $($testResultSummary.Failures)"
		AddLine $md "- Errors: $($testResultSummary.Errors)"
		AddLine $md "- Skipped: $($testResultSummary.Skipped)"
		AddLine $md "- Date/Time: $($testResultSummary.Date) $($testResultSummary.Time)"
	}
	else {
		AddLine $md "- Missing file: $testResultsXmlPath"
	}
	AddLine $md ''

	AddLine $md '## ParameterSet Coverage (cmdlets)'
	AddLine $md "- Covered: $coveredTotal/$expectedTotal ($parameterSetCoveragePercent%)"
	AddLine $md ""
	if ($missingParameterSetsByCmdlet.Count -gt 0) {
		AddLine $md 'Missing ParameterSets:'
		foreach ($c in $missingParameterSetsByCmdlet) {
			$missingList = ($c.MissingParameterSets -join ', ')
			AddLine $md "- $($c.Name): $missingList"
		}
		AddLine $md ''
	}
	else {
		AddLine $md "All expected ParameterSets are covered (based on test-results.xml)."
		AddLine $md ''
	}

	AddLine $md "## Results by Cmdlet / ParameterSet (from test-results.xml)"
	if ($cmdletsStats.Count -gt 0) {
		AddLine $md ''
		AddLine $md '| Cmdlet | ParameterSet | Total | Passed | Failed | Skipped |'
		AddLine $md '|---|---|---:|---:|---:|---:|'
		foreach ($c in @($cmdletsStats)) {
			$hasPerSet = $false
			foreach ($ps in @($c.ByParameterSet)) {
				$hasPerSet = $true
				$setDisplay = if ($ps.Name -eq '__Cmdlet__') { '(cmdlet)' } else { $ps.Name }
				$s = $ps.Stats
				AddLine $md "| $($c.Name) | $setDisplay | $($s.Total) | $($s.Passed) | $($s.Failed) | $($s.Skipped) |"
			}

			if (-not $hasPerSet) {
				$s = $c.Totals
				AddLine $md "| $($c.Name) | (none) | $($s.Total) | $($s.Passed) | $($s.Failed) | $($s.Skipped) |"
			}
		}
		AddLine $md ''
	}
	else {
		AddLine $md '- No cmdlet statistics extracted from test-results.xml.'
		AddLine $md ''
	}

	AddLine $md '## Files'
	AddLine $md "- test-results.xml: $testResultsXmlPath"
	AddLine $md "- cmdlets.parametersets.json: $cmdletsParameterSetsJsonPath"
	AddLine $md "- coverage-summary.json: $summaryJsonPath"

	Set-Content -LiteralPath $reportMdPath -Value $md.ToString()

	return $summary
}


##################################################
# CUSTOM SHOULD OPERATORS
##################################################

function Register-ShouldOperator {
	<#
	.SYNOPSIS
	Register a custom Should operator in Pester.

	.DESCRIPTION
	Registers a custom Should operator in Pester with Add-ShouldOperator.
	If custom operator is already registered, registration is skipped.

	.EXAMPLE
	Register-ShouldOperator -Name 'MyOperator' -FunctionName 'ShouldMyOperator'
	#>

	[CmdletBinding()]
	[OutputType([void])]
	param(
		# The name of the assertion. This will become a Named Parameter of Should.
		[Parameter(Mandatory)]	[string]$Name,

		# Name of the internal function implementing the assertion logic.
		[Parameter(Mandatory)]	[string]$FunctionName,

		# A list of aliases for the Named Parameter.
		[Parameter()]	[string[]]$Alias,

		# Does the test function support passing an array of values to test.
		[Parameter()]	[switch]$SupportsArray
	)

	Process {
		if (Get-ShouldOperator | Where-Object { $_.Name -eq $Name }) {
			Write-Verbose "Should operator '$Name' is already registered. Skipping registration."
			return
		}
		elseif ($cmd = Get-Command -Name $FunctionName -ErrorAction SilentlyContinue) {
			$params = @{
				Name         = $Name
				InternalName = $FunctionName
				Test         = $cmd.ScriptBlock
			}
			if ($Alias -and $Alias.Count -gt 0) {
				$params['Alias'] = $Alias
			}
			if ($SupportsArray) {
				$params['SupportsArray'] = $true
			}
			Write-Verbose "Registering Should operator with Add-ShouldOperator: $($params | Out-String)"
			Add-ShouldOperator @params
		}
		else {
			throw "Function '$FunctionName' not found. Cannot register Should operator '$Name'."
		}
	}
}

function ShouldTranscriptExecutionMatch {
	<#
	.SYNOPSIS
	Execute a ScriptBlock under transcript capture and verify the output with a regex.

	.DESCRIPTION
	Should-TranscriptExecutionMatch starts a transcript in the current TestDrive (or a temp folder), runs the
	provided ScriptBlock, and then evaluates the transcript content against a multiline regular expression. The
	result is returned as a Pester.ShouldResult, making it compatible with native Should semantics (including -Not).
	Transcript files are automatically deleted once processed.

	.EXAMPLE
	{ Some-Command -WhatIf } | Should -TranscriptExecutionMatch 'What if:'

	Runs Some-Command -WhatIf and verifies that the WhatIf output is present in the transcript.
	#>

	[CmdletBinding()]
	[OutputType([Pester.ShouldResult])]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		'PSReviewUnusedParameter', 'CallerSessionState', Justification = 'Pester internal parameter'
	)]
	param(
		# The ScriptBlock to execute under transcript capture.
		[Parameter(Mandatory)]	[scriptblock]$ActualValue,

		# Regular expression that must match the transcript output (supports multiline / dot-all).
		[Parameter(Mandatory)]	[string]$ExpectedPattern,

		# Indicates the expectation should be negated (set by Should -Not).
		[Parameter()]	[switch]$Negate,

		# Optional justification appended to failure messages.
		[Parameter()]	[string]$Because,

		# Internal Pester parameter for session state (automatically provided).
		[Parameter()]	[System.Management.Automation.SessionState]$CallerSessionState
	)

	Process {
		if (-not $ActualValue) {
			return [Pester.ShouldResult]@{
				Succeeded      = $false
				FailureMessage = 'TranscriptExecutionMatch requires a ScriptBlock as actual value.'
			}
		}

		$transcriptRoot = $null
		try {
			$transcriptRoot = Get-Variable -Name TestDrive -ValueOnly -ErrorAction Stop
		}
		catch {
			$transcriptRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'KubaPesterTranscripts'
		}

		if (-not (Test-Path -LiteralPath $transcriptRoot)) {
			$null = New-Item -Path $transcriptRoot -ItemType Directory -Force
		}

		$transcriptPath = Join-Path $transcriptRoot ("transcript-{0}.txt" -f ([guid]::NewGuid()))
		$errorRecord = $null

		$null = Start-Transcript -Path $transcriptPath -Force
		try {
			& $ActualValue
		}
		catch {
			$errorRecord = $_
		}
		finally {
			$null = Stop-Transcript
		}

		if ($errorRecord) {
			$null = Remove-Item -LiteralPath $transcriptPath -ErrorAction SilentlyContinue
			throw $errorRecord
		}

		$content = Get-Content -LiteralPath $transcriptPath -Raw -ErrorAction Stop
		$null = Remove-Item -LiteralPath $transcriptPath -ErrorAction SilentlyContinue

		$regexOptions = (
			[System.Text.RegularExpressions.RegexOptions]::Singleline -bor
			[System.Text.RegularExpressions.RegexOptions]::Multiline
		)
		$matchesPattern = [regex]::IsMatch($content, $ExpectedPattern, $regexOptions)
		$succeeded = if ($Negate) { -not $matchesPattern } else { $matchesPattern }

		if ($succeeded) {
			return [Pester.ShouldResult]@{ Succeeded = $true }
		}

		$becauseText = if ($Because) { " because $Because" } else { '' }
		$previewLength = 1200

		if ($content.Length -le $previewLength) {
			$preview = $content
		}
		else {
			$preview = $content.Substring(0, $previewLength) + ' …'
		}

		$failureMessage = if ($Negate) {
			"Transcript output unexpectedly matched pattern '$ExpectedPattern'$becauseText."
		}
		else {
			"Transcript output did not match pattern '$ExpectedPattern'$becauseText."
		}

		return [Pester.ShouldResult]@{
			Succeeded      = $false
			FailureMessage = $failureMessage
			ExpectResult   = @{
				Actual   = $preview
				Expected = $ExpectedPattern
				Because  = $Because
			}
		}
	}
}

function ShouldHaveSameItems {
	<#
	.SYNOPSIS
	Compare two collections for equivalence using Compare-Object.

	.DESCRIPTION
	Should-HaveSameItems compares two collections and succeeds if they contain the same elements,
	regardless of order. It uses Compare-Object internally, so the test passes when Compare-Object returns
	no differences.

	.EXAMPLE
	$actual = @('a', 'b', 'c')
	$expected = @('c', 'a', 'b')
	$actual | Should -HaveSameItems $expected

	Verifies that both collections contain the same elements (order-independent).
	#>

	[CmdletBinding()]
	[OutputType([Pester.ShouldResult])]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		'PSReviewUnusedParameter', 'CallerSessionState', Justification = 'Pester internal parameter'
	)]
	param(
		# The actual collection to compare.
		[Parameter(Mandatory)]	[AllowNull()] [object]$ActualValue,

		# The expected collection to compare against.
		[Parameter(Mandatory)]	[AllowNull()] [object]$ExpectedValue,

		# Indicates the expectation should be negated (set by Should -Not).
		[Parameter()]	[switch]$Negate,

		# Optional justification appended to failure messages.
		[Parameter()]	[string]$Because,

		# Internal Pester parameter for session state (automatically provided).
		[Parameter()]	[System.Management.Automation.SessionState]$CallerSessionState
	)

	Process {
		# Handle null cases
		$actualIsNull = $null -eq $ActualValue
		$expectedIsNull = $null -eq $ExpectedValue

		if ($actualIsNull -and $expectedIsNull) {
			$differences = $null
		}
		elseif ($actualIsNull -or $expectedIsNull) {
			$differences = @([PSCustomObject]@{
				InputObject   = if ($actualIsNull) { $ExpectedValue } else { $ActualValue }
				SideIndicator = if ($actualIsNull) { '=>' } else { '<=' }
			})
		}
		else {
			$differences = @(Compare-Object -ReferenceObject @($ExpectedValue) -DifferenceObject @($ActualValue))
		}

		$hasDifferences = $differences.Count -gt 0
		$succeeded = if ($Negate) { $hasDifferences } else { -not $hasDifferences }

		if ($succeeded) {
			return [Pester.ShouldResult]@{ Succeeded = $true }
		}

		$becauseText = if ($Because) { " because $Because" } else { '' }

		if ($Negate) {
			$failureMessage = "Collections are equivalent but should not be$becauseText."
		}
		else {
			$diffSummary = $differences | ForEach-Object {
				$indicator = if ($_.SideIndicator -eq '<=') { 'Missing' } else { 'Extra' }
				"  [$indicator] $($_.InputObject)"
			}
			$diffText = $diffSummary -join "`n"
			$failureMessage = "Collections are not equivalent$becauseText.`nDifferences:`n$diffText"
		}

		return [Pester.ShouldResult]@{
			Succeeded      = $false
			FailureMessage = $failureMessage
			ExpectResult   = @{
				Actual   = $ActualValue
				Expected = $ExpectedValue
				Because  = $Because
			}
		}
	}
}

function ShouldHaveItems {
	<#
	.SYNOPSIS
	Verify that a collection contains at least all the specified items.

	.DESCRIPTION
	Should-HaveItems checks that the actual collection contains at least all the expected items.
	Extra items in the actual collection are allowed.

	.EXAMPLE
	$actual = @('a', 'b', 'c', 'd')
	$expected = @('b', 'a')
	$actual | Should -HaveItems $expected

	Verifies that the actual collection contains at least 'a' and 'b'.
	#>

	[CmdletBinding()]
	[OutputType([Pester.ShouldResult])]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
		'PSReviewUnusedParameter', 'CallerSessionState', Justification = 'Pester internal parameter'
	)]
	param(
		# The actual collection to check.
		[Parameter(Mandatory)]	[object]$ActualValue,

		# The items that must be present in the actual collection.
		[Parameter(Mandatory)]	[object]$ExpectedValue,

		# Indicates the expectation should be negated (set by Should -Not).
		[Parameter()]	[switch]$Negate,

		# Optional justification appended to failure messages.
		[Parameter()]	[string]$Because,

		# Internal Pester parameter for session state (automatically provided).
		[Parameter()]	[System.Management.Automation.SessionState]$CallerSessionState
	)

	Process {
		$actualArray = @($ActualValue)
		$expectedArray = @($ExpectedValue)

		# Use Compare-Object to find items in expected but not in actual (SideIndicator '<=')
		$comparison = @(Compare-Object -ReferenceObject $expectedArray -DifferenceObject $actualArray -IncludeEqual)
		$missingItems = @(
			$comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
		)

		$hasMissing = $missingItems.Count -gt 0
		$succeeded = if ($Negate) { $hasMissing } else { -not $hasMissing }

		if ($succeeded) {
			return [Pester.ShouldResult]@{ Succeeded = $true }
		}

		$becauseText = if ($Because) { " because $Because" } else { '' }

		if ($Negate) {
			$failureMessage = "Collection contains all expected items but should not$becauseText."
		}
		else {
			$missingText = ($missingItems | ForEach-Object { "  [Missing] $_" }) -join "`n"
			$failureMessage = "Collection is missing expected items$becauseText.`n$missingText"
		}

		return [Pester.ShouldResult]@{
			Succeeded      = $false
			FailureMessage = $failureMessage
			ExpectResult   = @{
				Actual   = $ActualValue
				Expected = $ExpectedValue
				Because  = $Because
			}
		}
	}
}


##################################################
# POST-INIT
##################################################

if (!$Script:_PwshTestToolsPostInit) {
	# Register operators when this file is loaded
	Register-ShouldOperator -Name TranscriptExecutionMatch -FunctionName ShouldTranscriptExecutionMatch
	Register-ShouldOperator -Name HaveSameItems -FunctionName ShouldHaveSameItems -SupportsArray
	Register-ShouldOperator -Name HaveItems -FunctionName ShouldHaveItems -SupportsArray

	$Script:_PwshTestToolsPostInit = $true
}
