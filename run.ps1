#!/usr/bin/env pwsh

<#
.SYNOPSIS
	Build, package, run tests and generate documentation for the PoSh.FluidTemplateEngine module.

.DESCRIPTION
	This script provides a unified entrypoint for common development tasks for the `PoSh.FluidTemplateEngine` project:
	- Building and packaging the PowerShell module
	- Running Pester tests
	- Generating Markdown documentation
#>

[CmdletBinding()]
param(
	# Mode to run the script :
	# - 'Package': Build and packaging the PowerShell module.
	# - 'Tests': Run Pester tests.
	# - 'Documentation': Generate Markdown documentation.
	# - 'All': Run all tasks (Package, Tests, Documentation).
	[Parameter(Mandatory)][ValidateSet('Package', 'Tests', 'Documentation', 'All')]	[string]$Mode,

	# Build configuration: 'Release' (default) or 'Debug'
	[Parameter()]	[string]$BuildConfig = 'Release',

	# Path of PSD1 module to use for generating documentation or running tests.
	# If not specified, will use the one in `out/publish/PoSh.FluidTemplateEngine`.
	[Parameter()]   [string]$BuildedPSD1Path,

	# The verbosity of output for `-Mode Tests`, options are: 'None', 'Normal', 'Detailed' and 'Diagnostic'.
	# If not specified, value defined in `_pester.config.psd1` will be used.
	[Parameter()]	[ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic', '')]
	[string]$Verbosity = 'Detailed',

	# The verbosity of stacktrace output for `-Mode Tests`, options are: 'None', 'FirstLine', 'Filtered' and 'Full'.
	# If not specified, value defined in `_pester.config.psd1` will be used.
	[Parameter()]	[ValidateSet('None', 'FirstLine', 'Filtered', 'Full', '')]
	[string]$StackTraceVerbosity = 'Filtered',

	# Override Pester configuration (advanced usage, only for `-Mode Tests`).
	[Parameter()]   [hashtable]$PesterConfig
)


##############################
# INIT & CONFIG
##############################

$ErrorActionPreference = 'Stop'
$global:ProgressPreference = 'SilentlyContinue'	# Suppress progress bars during tests
$global:ConfirmPreference = 'None'				# Disable confirmation prompts during tests

$ProjectRoot = $PSScriptRoot
$ModuleName = 'PoSh.FluidTemplateEngine'
$OutBase = Join-Path $ProjectRoot "out/bin/$BuildConfig/net8.0"
$PublishBase = Join-Path $ProjectRoot 'out/publish'
$ModulePath = Join-Path $PublishBase $ModuleName
$DocsPath = Join-Path $ProjectRoot 'docs'

if (!$BuildedPSD1Path) {
	$BuildedPSD1Path = Join-Path $ModulePath "$ModuleName.psd1"
}


##############################
# BUILD FUNCTIONS
##############################

function Build-Package {
	Write-Info "`n=== Package Mode ==="

	Write-Info 'Clean build...'
	dotnet clean -c $BuildConfig
	if ($LASTEXITCODE -ne 0) { exit 1 }

	Write-Info 'Building module...'
	dotnet build -c $BuildConfig
	if ($LASTEXITCODE -ne 0) { exit 1 }

	Step-PostBuild

	Write-Info "Packaging to: $ModulePath"
	if (Test-Path $ModulePath) { Remove-Item $ModulePath -Recurse -Force }
	New-Item -ItemType Directory -Path $ModulePath -Force | Out-Null

	# Copy binaries and runtimes
	Copy-Item -Path "$OutBase/*" -Destination $ModulePath -Recurse -Force

	# Clean up build artifacts not needed for distribution
	Get-ChildItem -Path $ModulePath -Filter '*.pdb' -Recurse | Remove-Item -Force

	Write-Success '✅ Module packaged successfully!'
	Write-Host "Location: $ModulePath`n"
}

function Step-PostBuild {
	Write-Host "" # New line for separation

	$helpFile = Join-Path $OutBase 'PoSh.FluidTemplateEngine.dll-Help.xml'
	Write-Info "PostBuild: Apply final transforms to $helpFile..."
	if (Test-Path $helpFile) {
		$content = Get-Content -Path $helpFile -Raw
		# Remove leading spaces and '\§' markers so the line starts with the character after '§'
		$content = $content -replace '(?m)^[ \t]*\\§',''
		# Normalize escaped newlines and tabs to actual newlines and tabs
		$content = $content.Replace('\n', "  `n").Replace('\t', "`t")

		# Simplify .NET generic type names to PowerShell notation
		$content = SimplifyTypeNames $content

		Set-Content -Path $helpFile -Value $content
	} else {
		Write-Warning "PostBuild: Help file not found at $helpFile. Skipping transform."
	}

	Write-Host "" # New line for separation
}


##############################
# RUN TESTS FUNCTIONS
##############################

function Invoke-Tests {
	Write-Info "`n=== Tests Mode ==="

	# Load test tools functions
	. "$ProjectRoot/tests/_pwsh.tests.tools.ps1"

	# Run tests in a dedicated PowerShell job to force import new builded DLL
	Invoke-TestsInJob -CoverageReport `
		-Verbosity $Verbosity `
		-StackTraceVerbosity $StackTraceVerbosity `
		-PesterConfig $PesterConfig
}


##############################
# BUILD DOC FUNCTIONS
##############################

function Build-Documentation {
	Write-Info "`n=== Documentation Mode ==="

	$moduleXmlHelp = Join-Path $ModulePath "$ModuleName.dll-Help.xml"
	if (-not (Test-Path $moduleXmlHelp)) {
		throw "Module help file not found at $moduleXmlHelp. Run in 'Package' mode first to build."
	}

	# Import built PoSH.FluidTemplateEngine and PoSh.CmdletDoc
	Import-Module $BuildedPSD1Path -Force
	Import-ModuleIfExists PoSh.CmdletDoc

	Write-Info "Generating cmdlet documentation..."
	Write-Host "  Module:  $BuildedPSD1Path"
	Write-Host "  Output:  $DocsPath"

	# Use PoSh.CmdletDoc module to generate docs
	$result = New-CmdletDocumentation `
		-ModulePath $BuildedPSD1Path `
		-OutputDirectory $DocsPath `
		-ModuleNameFilter 'PoSh.FluidTemplateEngine'

	Write-Success "✅ Documentation generated for $($result.Count) cmdlets"
	Write-Info "  Cmdlets dir: $($result.CmdletsDir)"
	Write-Info "  Index file:  $($result.ListFile)"
}

function SimplifyTypeNames([string]$Content) {
	<#
	.SYNOPSIS
	Simplifies .NET type names to PowerShell notation.

	.DESCRIPTION
	Converts fully qualified .NET type names to their PowerShell equivalents:
	- System.String -> string
	- System.Int32 -> int
	- System.Collections.Generic.Dictionary`2[[T1],[T2]] -> Dictionary[T1,T2]
	#>

	# Map of .NET types to PowerShell notation
	$typeMap = @{
		'System\.String'	 = 'string'
		'System\.Int32'	  = 'int'
		'System\.Int64'	  = 'long'
		'System\.Double'	 = 'double'
		'System\.Boolean'	= 'bool'
		'System\.Single'	 = 'float'
		'System\.Byte'	   = 'byte'
		'System\.Char'	   = 'char'
		'System\.Decimal'	= 'decimal'
		'System\.Object'	 = 'object'
	}

	# Step 1: Simplify fully qualified Dictionary`2[[T1],[T2]] to Dictionary[T1,T2]
	$content = $content -replace `
		'System\.Collections\.Generic\.Dictionary`2\[\[([^\,]+)[^\]]*\],\[([^\,]+)[^\]]*\]\]', `
		'Dictionary[$1,$2]'

	# Step 2: Fix parameterValue that have Dictionary`2 by capturing the actual type from adjacent dev:type
	# This handles: <command:parameterValue>Dictionary`2</command:parameterValue><dev:type><maml:name>Dictionary[...]</maml:name>
	$content = $content -replace `
		'(<command:parameterValue[^>]*>)Dictionary`2(</command:parameterValue>)\s*(<dev:type>\s*<maml:name>)(Dictionary\[[^\]]+\])', `
		'$1$4$2$3$4'

	# Step 3: Fix parameterValue that have List`1 by same approach
	$content = $content -replace `
		'(<command:parameterValue[^>]*>)List`1(</command:parameterValue>)\s*(<dev:type>\s*<maml:name>)(List\[[^\]]+\])', `
		'$1$4$2$3$4'

	# Step 4: Simplify List`1[[fulltype]] to List[type]
	$content = $content -replace `
		'System\.Collections\.Generic\.List`1\[\[([^\,]+)[^\]]*\]\]', `
		'List[$1]'

	# Step 5: Simplify Hashtable
	$content = $content -replace 'System\.Collections\.Hashtable', 'Hashtable'

	# Step 6: Replace fully qualified type names in the simplified generics
	foreach ($key in $typeMap.Keys) {
		$value = $typeMap[$key]
		$content = $content -replace $key, $value
	}

	return $content
}


##############################
# HELPER FUNCTIONS
##############################

function Write-Info([string]$Message) {
	Write-Host $Message -ForegroundColor Cyan
}

function Write-Success([string]$Message) {
	Write-Host $Message -ForegroundColor Green
}

function Import-ModuleIfExists([string]$ModuleName) {
	if ((Get-Module -Name $ModuleName)) {
		Write-Verbose "Module '$ModuleName' is already imported."
		return
	}

	try {
		Import-Module $ModuleName
	}
	catch {
		if ($_.FullyQualifiedErrorId -like "Modules_ModuleNotFound*") {
			Write-Error ("Module '$ModuleName' not found. " + `
				"Use 'Install-Module $ModuleName' to install it from the PowerShell Gallery.")
		} else {
			Write-Error "Failed to import module from '$ModuleName': $($_.Exception.Message)"
		}
	}
}


##############################
# MAIN
##############################

if ($Mode -in 'Package','All') {
	Build-Package
}
if ($Mode -in 'Tests','All') {
	Invoke-Tests
}
if ($Mode -in 'Documentation','All') {
	Build-Documentation
}
