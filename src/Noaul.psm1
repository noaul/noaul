Set-StrictMode -Version Latest

$moduleRoot = $PSScriptRoot

Import-Module (Join-Path $moduleRoot 'Noaul.Catalog.psm1') -Force
Import-Module (Join-Path $moduleRoot 'Noaul.Installer.psm1') -Force
Import-Module (Join-Path $moduleRoot 'Noaul.Docker.psm1') -Force
Import-Module (Join-Path $moduleRoot 'Noaul.UI.psm1') -Force

Export-ModuleMember -Function `
    Get-NoaulComponentCatalog, `
    Get-NoaulComponentById, `
    ConvertTo-NoaulComponentIds, `
    Get-NoaulCurrentPlatform, `
    Resolve-NoaulComponentInstallMethod, `
    Resolve-NoaulComponentPackage, `
    Get-NoaulDefaultInstallRoot, `
    Get-NoaulPathHints, `
    New-NoaulInstallPlan, `
    New-NoaulUpdatePlan, `
    New-NoaulDockerServiceFiles, `
    ConvertTo-YamlScalar, `
    Invoke-NoaulInstallPlan, `
    Invoke-NoaulUpdatePlan, `
    Start-Noaul
