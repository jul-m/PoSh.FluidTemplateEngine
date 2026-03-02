@{
    RootModule = 'PoSh.FluidTemplateEngine.dll'
    ModuleVersion = '2.31.1'
    GUID = '866c43a7-7eb8-4bac-b42e-0ad2398edb34'
    Author = 'jul-m'
    CompanyName = 'jul-m'
    Copyright = 'Apache License 2.0'
    Description = 'A PowerShell module for easy rendering of Liquid templates using the high-performance Fluid .NET library.'
    PowerShellVersion = '7.0'
    DotNetFrameworkVersion = '8.0'
    CLRVersion = '8.0'

	CmdletsToExport = @(
		'Format-LiquidString'
		'Get-FluidModuleConfig'
		'Invoke-FluidFile'
		'Invoke-FluidTemplate'
		'New-FluidTemplate'
		'Register-FluidType'
		'Register-LiquidBlock'
		'Register-LiquidFilter'
		'Register-LiquidOperator'
		'Register-LiquidTag'
		'Set-FluidModuleConfig'
	)

    PrivateData = @{
        PSData = @{
            Tags = @(
                'Liquid'
                'Fluid'
                'Template'
                'TemplateEngine'
                'Rendering'
                'Markdown'
                'Automation'
            )
            LicenseUri = 'https://github.com/jul-m/PoSh.FluidTemplateEngine/blob/main/LICENSE'
            ProjectUri = 'https://github.com/jul-m/PoSh.FluidTemplateEngine'
            ReleaseNotes = 'https://github.com/jul-m/PoSh.FluidTemplateEngine/releases'
            IconUri = ''
            Prerelease = ''
        }
    }
}
