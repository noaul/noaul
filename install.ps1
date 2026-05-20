[CmdletBinding()]
param(
    [string[]] $Install = @(),
    [string[]] $DockerService = @(),
    [switch] $NoPrompt,
    [switch] $DryRun,
    [switch] $Update,
    [switch] $ListComponents,
    [string] $InstallRoot,
    [switch] $NoLogo
)

$ErrorActionPreference = 'Stop'

function Resolve-NoaulModulePath {
    $localModule = Join-Path $PSScriptRoot 'src/Noaul.psm1'
    if ($PSScriptRoot -and (Test-Path -LiteralPath $localModule)) {
        return $localModule
    }

    $cacheRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-installer'
    $cacheSrc = Join-Path $cacheRoot 'src'
    $cachedModule = Join-Path $cacheSrc 'Noaul.psm1'

    if (-not (Test-Path -LiteralPath $cacheSrc)) {
        New-Item -ItemType Directory -Path $cacheSrc -Force | Out-Null
    }

    $moduleUrl = 'https://raw.githubusercontent.com/noaul/noaul/main/src/Noaul.psm1'
    Invoke-WebRequest -UseBasicParsing -Uri $moduleUrl -OutFile $cachedModule
    return $cachedModule
}

$modulePath = Resolve-NoaulModulePath
Import-Module $modulePath -Force

$startArgs = @{
    Install = $Install
    DockerService = $DockerService
    NoPrompt = $NoPrompt
    DryRun = $DryRun
    Update = $Update
    ListComponents = $ListComponents
    NoLogo = $NoLogo
}

if (-not [string]::IsNullOrWhiteSpace($InstallRoot)) {
    $startArgs.InstallRoot = $InstallRoot
}

Start-Noaul @startArgs
