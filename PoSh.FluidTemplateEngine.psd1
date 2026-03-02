@{
    RootModule = 'PoSh.FluidTemplateEngine.dll'
    ModuleVersion = '0.1.0'
    GUID = 'c3bb83d2-3cff-45b2-a304-f284200b9ee8'
    Author = 'jul-m'
    CompanyName = 'jul-m'
    Copyright = '(c) 2025 jul-m. All rights reserved.'
    Description = 'Binary PowerShell module for rendering Liquid templates using the high-performance Fluid .NET library. Supports custom filters, tags, blocks, operators, strict modes, includes, macros, and more.'
    PowerShellVersion = '7.0'
    DotNetFrameworkVersion = '8.0'
    CLRVersion = '8.0'

    # Binary module - cmdlets exported automatically from DLL
    FunctionsToExport = @()
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
    VariablesToExport = @()
    AliasesToExport = @()

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
                'CodeGeneration'
                'Binary'
                'DotNet'
            )
            LicenseUri = 'https://github.com/jul-m/PoSh.FluidTemplateEngine/blob/main/LICENSE'
            ProjectUri = 'https://github.com/jul-m/PoSh.FluidTemplateEngine'
            IconUri = ''
            ReleaseNotes = 'https://github.com/jul-m/PoSh.FluidTemplateEngine/blob/main/CHANGELOG.md'
            Prerelease = ''
        }
    }
}
