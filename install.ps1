[CmdletBinding()]
param(
    [string[]] $Install = @(),
    [string[]] $DockerService = @(),
    [switch] $NoPrompt,
    [switch] $DryRun,
    [switch] $Update,
    [switch] $ListComponents,
    [string] $InstallRoot,
    [string] $Platform,
    [switch] $NoLogo
)

$ErrorActionPreference = 'Stop'

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
}
catch {
    # Process-scope policy is best effort; execution may already be controlled by a higher-precedence policy.
}

function Resolve-NoaulModulePath {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $localModule = Join-Path $PSScriptRoot 'src/Noaul.psm1'
        if (Test-Path -LiteralPath $localModule) {
            return $localModule
        }
    }

    $cacheRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-installer'
    $cacheSrc = Join-Path $cacheRoot 'src'
    $cachedModule = Join-Path $cacheSrc 'Noaul.psm1'

    if (-not (Test-Path -LiteralPath $cacheSrc)) {
        New-Item -ItemType Directory -Path $cacheSrc -Force | Out-Null
    }

    $moduleUrl = 'https://raw.githubusercontent.com/noaul/noaul/main/dist/Noaul.psm1'
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $moduleUrl -OutFile $cachedModule
    } catch {
        throw "Failed to download Noaul module from $moduleUrl. Check network connectivity. $_"
    }
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
if (-not [string]::IsNullOrWhiteSpace($Platform)) {
    $startArgs.Platform = $Platform
}

Start-Noaul @startArgs
