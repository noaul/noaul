Set-StrictMode -Version Latest

# --- Noaul.Catalog.psm1 ---
function Get-NoaulUserHome {
    if (-not [string]::IsNullOrWhiteSpace($HOME)) {
        return $HOME
    }

    $profilePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
    if (-not [string]::IsNullOrWhiteSpace($profilePath)) {
        return $profilePath
    }

    [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
}

function Join-NoaulOptionalPath {
    param(
        [AllowNull()]
        [string] $BasePath,
        [string] $ChildPath
    )

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return $null
    }

    Join-Path $BasePath $ChildPath
}

function Get-NoaulDefaultInstallRoot {
    Join-Path (Get-NoaulUserHome) '.noaul'
}

$script:PathHints = @(
    @{ EnvVar = 'SCOOP'; Default = (Join-Path (Get-NoaulUserHome) 'scoop'); Suffix = 'shims' }
    @{ EnvVar = $null; Default = $env:ProgramFiles; Suffix = 'Git/cmd' }
    @{ EnvVar = $null; Default = $env:ProgramFiles; Suffix = 'nodejs' }
    @{ EnvVar = $null; Default = $env:APPDATA; Suffix = 'npm' }
)

function Get-NoaulPathHints { $script:PathHints }

function Get-NoaulComponentCatalog {
    @(
        [pscustomobject]@{
            Id = 'winget'
            Name = 'Windows Package Manager'
            Category = 'Package Manager'
            DefaultSelected = $true
            InstallMethod = 'detect'
            LinuxInstallMethod = $null
            Package = ''
            LinuxPackage = $null
            Command = 'winget'
            Requires = @()
            Description = 'Windows package manager used for system and GUI tools.'
        }
        [pscustomobject]@{
            Id = 'scoop'
            Name = 'Scoop'
            Category = 'Package Manager'
            DefaultSelected = $true
            InstallMethod = 'bootstrap-scoop'
            LinuxInstallMethod = $null
            Package = 'get.scoop.sh'
            LinuxPackage = $null
            Command = 'scoop'
            Requires = @()
            Description = 'CLI-first package manager used by Noaul for developer tools.'
        }
        [pscustomobject]@{
            Id = 'git'
            Name = 'Git for Windows'
            Category = 'Core Dev'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'git'
            LinuxPackage = $null
            Command = 'git'
            Requires = @('scoop')
            Description = 'Required for most developer workflows.'
        }
        [pscustomobject]@{
            Id = 'curl'
            Name = 'curl'
            Category = 'Core Dev'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'curl'
            LinuxPackage = $null
            Command = 'curl.exe'
            Requires = @('scoop')
            Description = 'HTTP client used by bootstrap scripts and API workflows.'
        }
        [pscustomobject]@{
            Id = '7zip'
            Name = '7-Zip'
            Category = 'Core Dev'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = '7zip'
            LinuxPackage = $null
            Command = '7z'
            Requires = @('scoop')
            Description = 'Archive extraction utility used by many Windows toolchains.'
        }
        [pscustomobject]@{
            Id = 'ripgrep'
            Name = 'ripgrep'
            Category = 'Core Dev'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'ripgrep'
            LinuxPackage = $null
            Command = 'rg'
            Requires = @('scoop')
            Description = 'Fast code search command.'
        }
        [pscustomobject]@{
            Id = 'fd'
            Name = 'fd'
            Category = 'Core Dev'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'fd'
            LinuxPackage = $null
            Command = 'fd'
            Requires = @('scoop')
            Description = 'Fast file finder.'
        }
        [pscustomobject]@{
            Id = 'jq'
            Name = 'jq'
            Category = 'Core Dev'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'jq'
            LinuxPackage = $null
            Command = 'jq'
            Requires = @('scoop')
            Description = 'Command-line JSON processor.'
        }
        [pscustomobject]@{
            Id = 'gh'
            Name = 'GitHub CLI'
            Category = 'Core Dev'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'gh'
            LinuxPackage = $null
            Command = 'gh'
            Requires = @('scoop', 'git')
            Description = 'GitHub command-line client.'
        }
        [pscustomobject]@{
            Id = 'git-lfs'
            Name = 'Git LFS'
            Category = 'Core Dev'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'git-lfs'
            LinuxPackage = $null
            Command = 'git-lfs'
            Requires = @('scoop', 'git')
            Description = 'Large file support for Git repositories.'
        }
        [pscustomobject]@{
            Id = 'nodejs'
            Name = 'Node.js LTS'
            Category = 'Runtime'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'nodejs-lts'
            LinuxPackage = $null
            Command = 'node'
            Requires = @('scoop')
            Description = 'Required by npm-distributed AI CLIs.'
        }
        [pscustomobject]@{
            Id = 'npm'
            Name = 'npm'
            Category = 'Runtime'
            DefaultSelected = $true
            InstallMethod = 'virtual'
            LinuxInstallMethod = $null
            Package = ''
            LinuxPackage = $null
            Command = 'npm'
            Requires = @('nodejs')
            Description = 'Provided by Node.js; verified as a prerequisite for npm tools.'
        }
        [pscustomobject]@{
            Id = 'pnpm'
            Name = 'pnpm'
            Category = 'Node Tooling'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'pnpm'
            LinuxPackage = $null
            Command = 'pnpm'
            Requires = @('scoop', 'nodejs', 'npm')
            Description = 'Fast Node.js package manager.'
        }
        [pscustomobject]@{
            Id = 'python'
            Name = 'Python 3'
            Category = 'Runtime'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'python'
            LinuxPackage = $null
            Command = 'python'
            Requires = @('scoop')
            Description = 'Python runtime for automation, scripting, and AI tooling.'
        }
        [pscustomobject]@{
            Id = 'uv'
            Name = 'uv'
            Category = 'Python Tooling'
            DefaultSelected = $true
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'uv'
            LinuxPackage = $null
            Command = 'uv'
            Requires = @('scoop', 'python')
            Description = 'Fast Python package and project manager.'
        }
        [pscustomobject]@{
            Id = 'pipx'
            Name = 'pipx'
            Category = 'Python Tooling'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'pipx'
            LinuxPackage = $null
            Command = 'pipx'
            Requires = @('scoop', 'python')
            Description = 'Installs Python CLI applications in isolated environments.'
        }
        [pscustomobject]@{
            Id = 'ruff'
            Name = 'Ruff'
            Category = 'Python Tooling'
            DefaultSelected = $false
            InstallMethod = 'scoop'
            LinuxInstallMethod = $null
            Package = 'ruff'
            LinuxPackage = $null
            Command = 'ruff'
            Requires = @('scoop', 'python')
            Description = 'Fast Python linter and formatter.'
        }
        [pscustomobject]@{
            Id = 'visual-build-tools'
            Name = 'Visual Studio Build Tools'
            Category = 'Build Tools'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = $null
            Package = 'Microsoft.VisualStudio.2022.BuildTools'
            LinuxPackage = $null
            Command = ''
            Requires = @()
            Description = 'C++ build tools required by some native npm and Python packages.'
        }
        [pscustomobject]@{
            Id = 'powershell'
            Name = 'PowerShell 7'
            Category = 'Shell'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = $null
            Package = 'Microsoft.PowerShell'
            LinuxPackage = $null
            Command = 'pwsh'
            Requires = @()
            Description = 'Modern PowerShell runtime for Windows automation.'
        }
        [pscustomobject]@{
            Id = 'vscode'
            Name = 'Visual Studio Code'
            Category = 'Editor'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = $null
            Package = 'Microsoft.VisualStudioCode'
            LinuxPackage = $null
            Command = 'code'
            Requires = @()
            Description = 'Optional editor.'
        }
        [pscustomobject]@{
            Id = 'docker-desktop'
            Name = 'Docker Desktop'
            Category = 'Docker Runtime'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = $null
            Package = 'Docker.DockerDesktop'
            LinuxPackage = $null
            Command = 'docker'
            Requires = @()
            Description = 'Required for optional Docker services.'
        }
        [pscustomobject]@{
            Id = 'codex'
            Name = 'OpenAI Codex CLI'
            Category = 'AI CLI'
            DefaultSelected = $false
            InstallMethod = 'npm'
            LinuxInstallMethod = $null
            Package = '@openai/codex'
            LinuxPackage = $null
            Command = 'codex'
            Requires = @('nodejs', 'npm')
            Description = 'Optional OpenAI coding CLI. Noaul sets Codex reasoning effort to xhigh.'
        }
        [pscustomobject]@{
            Id = 'claude-code'
            Name = 'Claude Code'
            Category = 'AI CLI'
            DefaultSelected = $false
            InstallMethod = 'npm'
            LinuxInstallMethod = $null
            Package = '@anthropic-ai/claude-code'
            LinuxPackage = $null
            Command = 'claude'
            Requires = @('nodejs', 'npm')
            Description = 'Optional Anthropic Claude Code CLI.'
        }
        [pscustomobject]@{
            Id = 'kiro'
            Name = 'Kiro'
            Category = 'AI App'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = $null
            Package = 'Amazon.Kiro'
            LinuxPackage = $null
            Command = 'kiro'
            Requires = @()
            Description = 'Optional Kiro app from winget.'
        }
        [pscustomobject]@{
            Id = 'opencode'
            Name = 'OpenCode'
            Category = 'AI CLI'
            DefaultSelected = $false
            InstallMethod = 'npm'
            LinuxInstallMethod = $null
            Package = 'opencode-ai'
            LinuxPackage = $null
            Command = 'opencode'
            Requires = @('nodejs', 'npm')
            Description = 'Optional OpenCode CLI.'
        }
        [pscustomobject]@{
            Id = 'cc-switch'
            Name = 'CC Switch'
            Category = 'AI App'
            DefaultSelected = $false
            InstallMethod = 'winget'
            LinuxInstallMethod = 'cc-switch-cli'
            Package = 'farion1231.CC-Switch'
            LinuxPackage = 'https://github.com/saladday/cc-switch-cli/releases/latest/download/install.sh'
            Command = 'cc-switch'
            Requires = @()
            Description = 'Optional provider/config switcher for AI coding tools. Windows uses CC Switch; Linux uses cc-switch-cli.'
        }
        [pscustomobject]@{
            Id = 'cpa'
            Name = 'CLIProxyAPI / CPA'
            Category = 'Docker Service'
            DefaultSelected = $false
            InstallMethod = 'docker'
            LinuxInstallMethod = $null
            Package = 'eceasy/cli-proxy-api:latest'
            LinuxPackage = $null
            Command = ''
            Requires = @('docker-desktop')
            Description = 'Optional Docker service for CLI proxy API workflows.'
        }
        [pscustomobject]@{
            Id = 'cpa-usage-keeper'
            Name = 'CPA Usage Keeper'
            Category = 'Docker Service'
            DefaultSelected = $false
            InstallMethod = 'docker'
            LinuxInstallMethod = $null
            Package = 'ghcr.io/willxup/cpa-usage-keeper:latest'
            LinuxPackage = $null
            Command = ''
            Requires = @('docker-desktop')
            Description = 'Optional Docker dashboard/service for CPA usage tracking.'
        }
        [pscustomobject]@{
            Id = 'sub2api'
            Name = 'Sub2API'
            Category = 'Docker Service'
            DefaultSelected = $false
            InstallMethod = 'docker'
            LinuxInstallMethod = $null
            Package = 'weishaw/sub2api:latest'
            LinuxPackage = $null
            Command = ''
            Requires = @('docker-desktop')
            Description = 'Optional Docker service with PostgreSQL and Redis.'
        }
    )
}

function Get-NoaulComponentById {
    param(
        [Parameter(Mandatory)]
        [string] $Id
    )

    $component = Get-NoaulComponentCatalog | Where-Object { $_.Id -ieq $Id } | Select-Object -First 1
    if (-not $component) {
        throw "Unknown Noaul component: $Id"
    }

    $component
}

function ConvertTo-NoaulComponentIds {
    param([string[]] $Components = @())

    foreach ($component in @($Components)) {
        if ([string]::IsNullOrWhiteSpace($component)) {
            continue
        }

        foreach ($part in ($component -split ',')) {
            $id = $part.Trim()
            if (-not [string]::IsNullOrWhiteSpace($id)) {
                $id
            }
        }
    }
}

function Get-NoaulCurrentPlatform {
    $isLinuxVariable = Get-Variable -Name IsLinux -ErrorAction SilentlyContinue
    if ($isLinuxVariable -and [bool] $isLinuxVariable.Value) {
        return 'linux'
    }

    $isMacOSVariable = Get-Variable -Name IsMacOS -ErrorAction SilentlyContinue
    if ($isMacOSVariable -and [bool] $isMacOSVariable.Value) {
        return 'macos'
    }

    $isWindowsVariable = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
    if ($isWindowsVariable -and [bool] $isWindowsVariable.Value) {
        return 'windows'
    }

    try {
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
            return 'linux'
        }
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
            return 'macos'
        }
    }
    catch {
        # Windows PowerShell 5.1 does not expose PowerShell 7 platform variables.
    }

    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        return 'windows'
    }

    'linux'
}

function Resolve-NoaulComponentInstallMethod {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    if ($Platform -eq 'linux') {
        $linuxMethod = [string] $Component.LinuxInstallMethod
        if (-not [string]::IsNullOrWhiteSpace($linuxMethod)) {
            return $linuxMethod
        }
    }

    [string] $Component.InstallMethod
}

function Resolve-NoaulComponentPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    if ($Platform -eq 'linux') {
        $linuxPkg = [string] $Component.LinuxPackage
        if (-not [string]::IsNullOrWhiteSpace($linuxPkg)) {
            return $linuxPkg
        }
    }

    [string] $Component.Package
}

# --- Noaul.Installer.psm1 ---
function Update-NoaulCurrentPath {
    $hints = Get-NoaulPathHints
    $paths = foreach ($hint in @($hints)) {
        $basePath = [string] $hint.Default
        if ($hint.EnvVar) {
            $envValue = [System.Environment]::GetEnvironmentVariable([string] $hint.EnvVar)
            if (-not [string]::IsNullOrWhiteSpace($envValue)) {
                $basePath = $envValue
            }
        }

        Join-NoaulOptionalPath -BasePath $basePath -ChildPath ([string] $hint.Suffix)
    }

    foreach ($path in ($paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        if ((Test-Path -LiteralPath $path) -and ($env:Path -notlike "*$path*")) {
            $env:Path = "$env:Path;$path"
        }
    }
}

function New-NoaulInstallPlan {
    param(
        [string[]] $Components = @(),
        [bool] $IncludeRecommendedCore = $true,
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    $catalog = @(Get-NoaulComponentCatalog)

    # Build O(1) lookup hashtable keyed by lowercased Id
    $catalogMap = @{}
    foreach ($component in $catalog) {
        $catalogMap[$component.Id.ToLowerInvariant()] = $component
    }

    $selected = @{}

    if ($IncludeRecommendedCore) {
        foreach ($component in $catalog | Where-Object { $_.DefaultSelected }) {
            $selected[$component.Id.ToLowerInvariant()] = $true
        }
    }

    foreach ($componentId in @(ConvertTo-NoaulComponentIds -Components $Components)) {
        $key = $componentId.ToLowerInvariant()
        if (-not $catalogMap.ContainsKey($key)) {
            throw "Unknown Noaul component: $componentId"
        }
        $selected[$key] = $true
    }

    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($component in $catalog) {
            if (-not $selected.ContainsKey($component.Id.ToLowerInvariant())) {
                continue
            }

            $requiredIds = @($component.Requires) + @(Get-NoaulImplicitPrerequisiteIds -Component $component -Platform $Platform)
            foreach ($requiredId in @($requiredIds)) {
                $reqKey = $requiredId.ToLowerInvariant()
                if ($reqKey -eq $component.Id.ToLowerInvariant()) {
                    continue
                }
                if (-not $catalogMap.ContainsKey($reqKey)) {
                    throw "Unknown Noaul component dependency: $requiredId (required by $($component.Id))"
                }
                if (-not $selected.ContainsKey($reqKey)) {
                    $selected[$reqKey] = $true
                    $changed = $true
                }
            }
        }
    }

    $catalog | Where-Object { $selected.ContainsKey($_.Id.ToLowerInvariant()) }
}

function Get-NoaulImplicitPrerequisiteIds {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    $installMethod = Resolve-NoaulComponentInstallMethod -Component $Component -Platform $Platform
    switch ($installMethod) {
        'scoop' {
            'scoop'
        }
        'winget' {
            'winget'
        }
        'npm' {
            'nodejs'
            'npm'
        }
        'docker' {
            'docker-desktop'
        }
    }
}

function New-NoaulUpdatePlan {
    param(
        [string[]] $Components = @(),
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [AllowNull()]
        [string[]] $InstalledComponentIds = $null
    )

    $catalog = @(Get-NoaulComponentCatalog)
    $requested = @{}
    foreach ($componentId in @(ConvertTo-NoaulComponentIds -Components $Components)) {
        $component = Get-NoaulComponentById -Id $componentId
        $requested[$component.Id.ToLowerInvariant()] = $true
    }

    $installed = @{}
    if ($null -eq $InstalledComponentIds) {
        foreach ($componentId in @(Get-NoaulInstalledComponentIds -InstallRoot $InstallRoot -Platform $Platform)) {
            $installed[$componentId.ToLowerInvariant()] = $true
        }
    }
    else {
        foreach ($componentId in @(ConvertTo-NoaulComponentIds -Components $InstalledComponentIds)) {
            $component = Get-NoaulComponentById -Id $componentId
            $installed[$component.Id.ToLowerInvariant()] = $true
        }
    }

    $catalog | Where-Object {
        $key = $_.Id.ToLowerInvariant()
        $installed.ContainsKey($key) -and ($requested.Count -eq 0 -or $requested.ContainsKey($key))
    }
}

function New-NoaulSecret {
    param([int] $Bytes = 32)

    $buffer = New-Object byte[] $Bytes
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($buffer)
    }
    finally {
        $rng.Dispose()
    }

    ([System.BitConverter]::ToString($buffer) -replace '-', '').ToLowerInvariant()
}

function Get-NoaulSecretValue {
    param(
        [hashtable] $Secrets,
        [string] $Name,
        [int] $Bytes = 32
    )

    if ($Secrets -and $Secrets.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace([string] $Secrets[$Name])) {
        return [string] $Secrets[$Name]
    }

    New-NoaulSecret -Bytes $Bytes
}

function New-NoaulDirectory {
    param([Parameter(Mandatory)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-NoaulTextFile {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Content
    )

    $directory = Split-Path -Parent $Path
    if ($directory) {
        New-NoaulDirectory -Path $directory
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
    [pscustomobject]@{
        Path = $Path
        Kind = 'file'
    }
}

function Test-NoaulCommand {
    param([Parameter(Mandatory)][string] $Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-NoaulCommand {
    param(
        [Parameter(Mandatory)][string] $Display,
        [Parameter(Mandatory)][scriptblock] $ScriptBlock,
        [switch] $DryRun
    )

    if ($DryRun) {
        Write-Host "[dry-run] $Display"
        return
    }

    Write-Host "[run] $Display"
    $errorCountBefore = $Error.Count
    & $ScriptBlock
    if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
        throw "Command failed (exit code $LASTEXITCODE): $Display"
    }
    if ($Error.Count -gt $errorCountBefore) {
        $recentErrors = $Error[0..($Error.Count - $errorCountBefore - 1)]
        $terminating = $recentErrors | Where-Object {
            $_ -is [System.Management.Automation.ErrorRecord] -and
            $_.CategoryInfo.Category -eq 'OperationStopped'
        }
        if ($terminating) {
            throw "Command failed: $Display - $($terminating[0].Exception.Message)"
        }
    }
}

function Test-NoaulComponentCommand {
    param([Parameter(Mandatory)][pscustomobject] $Component)

    if (-not ($Component.PSObject.Properties.Name -contains 'Command')) {
        return $false
    }

    $command = [string] $Component.Command
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $false
    }

    Test-NoaulCommand -Name $command
}

function Test-NoaulScoopPackageInstalled {
    param([Parameter(Mandatory)][string] $Package)

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'scoop')) {
        return $false
    }

    & scoop prefix $Package *> $null
    $LASTEXITCODE -eq 0
}

function Test-NoaulWingetPackageInstalled {
    param([Parameter(Mandatory)][string] $Package)

    if (-not (Test-NoaulCommand -Name 'winget')) {
        return $false
    }

    & winget list --id $Package --exact *> $null
    $LASTEXITCODE -eq 0
}

function Test-NoaulNpmPackageInstalled {
    param([Parameter(Mandatory)][string] $Package)

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'npm')) {
        return $false
    }

    & npm list -g $Package --depth=0 *> $null
    $LASTEXITCODE -eq 0
}

function Test-NoaulDockerServiceInstalled {
    param(
        [Parameter(Mandatory)][string] $Id,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot)
    )

    switch ($Id) {
        'cpa' {
            $composePath = Join-Path $InstallRoot 'services/cpa-stack/docker-compose.yml'
            return ((Test-Path -LiteralPath $composePath) -and ((Get-Content -LiteralPath $composePath -Raw) -match 'cli-proxy-api'))
        }
        'cpa-usage-keeper' {
            $composePath = Join-Path $InstallRoot 'services/cpa-stack/docker-compose.yml'
            return ((Test-Path -LiteralPath $composePath) -and ((Get-Content -LiteralPath $composePath -Raw) -match 'cpa-usage-keeper'))
        }
        'sub2api' {
            $composePath = Join-Path $InstallRoot 'services/sub2api/docker-compose.yml'
            return ((Test-Path -LiteralPath $composePath) -and ((Get-Content -LiteralPath $composePath -Raw) -match 'sub2api'))
        }
        default {
            return $false
        }
    }
}

function Test-NoaulComponentInstalled {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    $installMethod = Resolve-NoaulComponentInstallMethod -Component $Component -Platform $Platform
    $package = Resolve-NoaulComponentPackage -Component $Component -Platform $Platform

    switch ($installMethod) {
        'detect' {
            return (Test-NoaulComponentCommand -Component $Component)
        }
        'bootstrap-scoop' {
            return (Test-NoaulComponentCommand -Component $Component)
        }
        'scoop' {
            return (Test-NoaulScoopPackageInstalled -Package $package)
        }
        'virtual' {
            return (Test-NoaulComponentCommand -Component $Component)
        }
        'winget' {
            return (Test-NoaulWingetPackageInstalled -Package $package)
        }
        'npm' {
            return (Test-NoaulNpmPackageInstalled -Package $package)
        }
        'cc-switch-cli' {
            return (Test-NoaulComponentCommand -Component $Component)
        }
        'docker' {
            return (Test-NoaulDockerServiceInstalled -Id ([string] $Component.Id) -InstallRoot $InstallRoot)
        }
        default {
            return (Test-NoaulComponentCommand -Component $Component)
        }
    }
}

function Get-NoaulInstalledComponentIds {
    param(
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    foreach ($component in @(Get-NoaulComponentCatalog)) {
        if (Test-NoaulComponentInstalled -Component $component -InstallRoot $InstallRoot -Platform $Platform) {
            $component.Id
        }
    }
}

function Assert-NoaulDetectedTool {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    $name = [string] $Component.Name
    $command = [string] $Component.Command
    if ($DryRun) {
        Write-Host "[dry-run] verify $name command: $command"
        return
    }

    Update-NoaulCurrentPath
    if (-not (Test-NoaulComponentCommand -Component $Component)) {
        throw "$name was not found. Install or enable $command first, then rerun Noaul."
    }

    Write-Host "[skip] $name is already available ($command)"
}

function Install-NoaulScoop {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Update-NoaulCurrentPath
    if (Test-NoaulCommand -Name 'scoop') {
        Write-Host '[skip] Scoop is already available'
        return
    }

    if ($DryRun) {
        Write-Host '[dry-run] install Scoop package manager'
        return
    }

    $installCommand = "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
    Invoke-NoaulCommand -Display 'install Scoop package manager from get.scoop.sh' -ScriptBlock {
        & powershell -NoProfile -ExecutionPolicy Bypass -Command $installCommand
    }
    Update-NoaulCurrentPath
}

function Install-NoaulScoopPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Update-NoaulCurrentPath
    if (Test-NoaulComponentCommand -Component $Component) {
        Write-Host "[skip] $($Component.Name) is already available"
        return
    }

    if (-not (Test-NoaulCommand -Name 'scoop')) {
        throw 'scoop was not found. Install Scoop first, then rerun Noaul.'
    }

    $package = [string] $Component.Package
    $name = [string] $Component.Name
    Invoke-NoaulCommand -Display "scoop install $package ($name)" -DryRun:$DryRun -ScriptBlock {
        & scoop install $package
    }
}

function Assert-NoaulVirtualComponent {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    $name = [string] $Component.Name
    $command = [string] $Component.Command
    if ($DryRun) {
        Write-Host "[dry-run] verify provided tool $name command: $command"
        return
    }

    Update-NoaulCurrentPath
    if (-not (Test-NoaulComponentCommand -Component $Component)) {
        throw "$name should be provided by its prerequisite, but $command was not found."
    }

    Write-Host "[ok] $name is available ($command)"
}

function Set-NoaulCodexDefaultReasoning {
    param(
        [string] $Effort = 'xhigh',
        [switch] $DryRun
    )

    $configDir = Join-Path $HOME '.codex'
    $configPath = Join-Path $configDir 'config.toml'
    $line = "model_reasoning_effort = `"$Effort`""

    if ($DryRun) {
        Write-Host "[dry-run] set Codex $line in $configPath"
        return
    }

    New-NoaulDirectory -Path $configDir
    if (Test-Path -LiteralPath $configPath) {
        $content = Get-Content -LiteralPath $configPath -Raw
        if ($content -match '(?m)^model_reasoning_effort\s*=') {
            $content = [regex]::Replace($content, '(?m)^model_reasoning_effort\s*=.*$', $line)
        }
        elseif ([string]::IsNullOrWhiteSpace($content)) {
            $content = "$line`r`n"
        }
        else {
            $content = $content.TrimEnd() + "`r`n$line`r`n"
        }
    }
    else {
        $content = "$line`r`n"
    }

    Set-Content -LiteralPath $configPath -Value $content -Encoding utf8
}

function Install-NoaulWingetPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    if (-not (Test-NoaulCommand -Name 'winget')) {
        throw 'winget was not found. Install App Installer from Microsoft Store or update Windows first.'
    }

    $id = [string] $Component.Package
    $name = [string] $Component.Name
    Invoke-NoaulCommand -Display "winget upgrade/install $name ($id)" -DryRun:$DryRun -ScriptBlock {
        & winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            & winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
        }
    }
}

function Update-NoaulWingetPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    if (-not (Test-NoaulCommand -Name 'winget')) {
        throw 'winget was not found. Install App Installer from Microsoft Store or update Windows first.'
    }

    $id = [string] $Component.Package
    $name = [string] $Component.Name
    Invoke-NoaulCommand -Display "winget upgrade $name ($id)" -DryRun:$DryRun -ScriptBlock {
        & winget upgrade --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    }
}

function Install-NoaulNpmPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'npm')) {
        throw 'npm was not found. Install Node.js LTS first, then rerun Noaul.'
    }

    $package = [string] $Component.Package
    $name = [string] $Component.Name
    Invoke-NoaulCommand -Display "npm install -g $package@latest ($name)" -DryRun:$DryRun -ScriptBlock {
        & npm install -g "$package@latest"
    }
}

function Install-NoaulCcSwitchCli {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $DryRun
    )

    if ($Platform -ne 'linux') {
        throw "cc-switch-cli is only supported on Linux by Noaul. Current platform: $Platform"
    }

    $url = Resolve-NoaulComponentPackage -Component $Component -Platform $Platform
    if ($DryRun) {
        Write-Host "[dry-run] install CC Switch CLI from $url with CC_SWITCH_FORCE=1"
        return
    }

    foreach ($command in @('bash', 'curl')) {
        if (-not (Test-NoaulCommand -Name $command)) {
            throw "$command was not found. Install $command first, then rerun Noaul."
        }
    }

    Invoke-NoaulCommand -Display "install CC Switch CLI from saladday/cc-switch-cli" -ScriptBlock {
        $oldForce = $env:CC_SWITCH_FORCE
        $env:CC_SWITCH_FORCE = '1'
        try {
            & bash -c "curl -fsSL $url | bash"
        }
        finally {
            if ($null -eq $oldForce) {
                Remove-Item Env:CC_SWITCH_FORCE -ErrorAction SilentlyContinue
            }
            else {
                $env:CC_SWITCH_FORCE = $oldForce
            }
        }
    }
}

function Update-NoaulScoop {
    param([switch] $DryRun)

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'scoop')) {
        throw 'scoop was not found. Nothing can be updated through Scoop.'
    }

    Invoke-NoaulCommand -Display 'scoop update' -DryRun:$DryRun -ScriptBlock {
        & scoop update
    }
}

function Update-NoaulScoopPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'scoop')) {
        throw 'scoop was not found. Nothing can be updated through Scoop.'
    }

    $package = [string] $Component.Package
    $name = [string] $Component.Name
    Invoke-NoaulCommand -Display "scoop update $package ($name)" -DryRun:$DryRun -ScriptBlock {
        & scoop update $package
    }
}

# Update delegates to install for npm (same command: npm install -g @latest)
function Update-NoaulNpmPackage {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Install-NoaulNpmPackage -Component $Component -DryRun:$DryRun
}

# Update delegates to install for cc-switch-cli (same installer script)
function Update-NoaulCcSwitchCli {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $DryRun
    )

    Install-NoaulCcSwitchCli -Component $Component -Platform $Platform -DryRun:$DryRun
}

function Invoke-NoaulInstallPlan {
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]] $Plan,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $DryRun
    )

    $dockerServices = @()
    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        switch ($installMethod) {
            'detect' {
                Assert-NoaulDetectedTool -Component $component -DryRun:$DryRun
            }
            'bootstrap-scoop' {
                Install-NoaulScoop -Component $component -DryRun:$DryRun
            }
            'scoop' {
                Install-NoaulScoopPackage -Component $component -DryRun:$DryRun
                Update-NoaulCurrentPath
            }
            'virtual' {
                Assert-NoaulVirtualComponent -Component $component -DryRun:$DryRun
            }
            'winget' {
                Install-NoaulWingetPackage -Component $component -DryRun:$DryRun
                Update-NoaulCurrentPath
            }
            'npm' {
                Install-NoaulNpmPackage -Component $component -DryRun:$DryRun
                if ($component.Id -eq 'codex') {
                    Set-NoaulCodexDefaultReasoning -Effort 'xhigh' -DryRun:$DryRun
                }
            }
            'cc-switch-cli' {
                Install-NoaulCcSwitchCli -Component $component -Platform $Platform -DryRun:$DryRun
            }
            'docker' {
                $dockerServices += $component.Id
            }
            default {
                throw "Unsupported install method for $($component.Id): $installMethod"
            }
        }
    }

    if ($dockerServices.Count -gt 0) {
        Start-NoaulDockerServices -Services $dockerServices -InstallRoot $InstallRoot -DryRun:$DryRun
    }
}

function Invoke-NoaulUpdatePlan {
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]] $Plan,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $DryRun
    )

    $dockerServices = @()
    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        switch ($installMethod) {
            'detect' {
                Assert-NoaulDetectedTool -Component $component -DryRun:$DryRun
            }
            'bootstrap-scoop' {
                Update-NoaulScoop -DryRun:$DryRun
            }
            'scoop' {
                Update-NoaulScoopPackage -Component $component -DryRun:$DryRun
                Update-NoaulCurrentPath
            }
            'virtual' {
                Assert-NoaulVirtualComponent -Component $component -DryRun:$DryRun
            }
            'winget' {
                Update-NoaulWingetPackage -Component $component -DryRun:$DryRun
                Update-NoaulCurrentPath
            }
            'npm' {
                Update-NoaulNpmPackage -Component $component -DryRun:$DryRun
                if ($component.Id -eq 'codex') {
                    Set-NoaulCodexDefaultReasoning -Effort 'xhigh' -DryRun:$DryRun
                }
            }
            'cc-switch-cli' {
                Update-NoaulCcSwitchCli -Component $component -Platform $Platform -DryRun:$DryRun
            }
            'docker' {
                $dockerServices += $component.Id
            }
            default {
                throw "Unsupported update method for $($component.Id): $installMethod"
            }
        }
    }

    if ($dockerServices.Count -gt 0) {
        Update-NoaulDockerServices -Services $dockerServices -InstallRoot $InstallRoot -DryRun:$DryRun
    }
}

# --- Noaul.Docker.psm1 ---
function ConvertTo-YamlScalar {
    param([string] $Value)
    if ($Value -match '[:{}\[\],&*?|>!%@`#''"\\]') {
        return "`"$($Value -replace '"','\"')`""
    }
    $Value
}

function New-NoaulCpaStackFiles {
    param(
        [Parameter(Mandatory)]
        [string[]] $Services,
        [Parameter(Mandatory)]
        [string] $InstallRoot,
        [hashtable] $Secrets = @{}
    )

    $stackDir = Join-Path $InstallRoot 'services/cpa-stack'
    $dataDir = Join-Path $stackDir 'data'
    $authDir = Join-Path $stackDir 'auths'
    $logDir = Join-Path $stackDir 'logs'

    New-NoaulDirectory -Path $dataDir
    New-NoaulDirectory -Path $authDir
    New-NoaulDirectory -Path $logDir

    $includeCpa = $Services -contains 'cpa'
    $includeKeeper = $Services -contains 'cpa-usage-keeper'
    $managementKey = Get-NoaulSecretValue -Secrets $Secrets -Name 'CpaManagementKey' -Bytes 32
    $apiKey = Get-NoaulSecretValue -Secrets $Secrets -Name 'CpaApiKey' -Bytes 24
    $keeperPassword = Get-NoaulSecretValue -Secrets $Secrets -Name 'KeeperLoginPassword' -Bytes 24
    $created = New-Object System.Collections.Generic.List[object]

    $safeMgmtKey = ConvertTo-YamlScalar $managementKey
    $safeApiKey = ConvertTo-YamlScalar $apiKey
    $safeKeeperPwd = ConvertTo-YamlScalar $keeperPassword

    $envContent = @"
TZ=Asia/Shanghai
CPA_HOST_PORT=8317
CPA_MANAGEMENT_KEY=$managementKey
CPA_API_KEY=$apiKey
KEEPER_HOST_PORT=18088
KEEPER_LOGIN_PASSWORD=$keeperPassword
"@
    $created.Add((Write-NoaulTextFile -Path (Join-Path $stackDir '.env') -Content $envContent))

    if ($includeCpa) {
        $configContent = @"
host: 0.0.0.0
port: 8317
auth-dir: /root/.cli-proxy-api
debug: false
usage-statistics-enabled: true
remote-management:
  allow-remote: true
  secret-key: $safeMgmtKey
api-keys:
  - $safeApiKey
"@
        $created.Add((Write-NoaulTextFile -Path (Join-Path $stackDir 'config.yaml') -Content $configContent))
    }

    $serviceBlocks = New-Object System.Collections.Generic.List[string]
    if ($includeCpa) {
        $serviceBlocks.Add(@"
  cli-proxy-api:
    image: eceasy/cli-proxy-api:latest
    container_name: cli-proxy-api
    restart: unless-stopped
    environment:
      TZ: `${TZ:-Asia/Shanghai}
      MANAGEMENT_PASSWORD: `${CPA_MANAGEMENT_KEY}
    ports:
      - "127.0.0.1:`${CPA_HOST_PORT:-8317}:8317"
      - "127.0.0.1:8085:8085"
      - "127.0.0.1:1455:1455"
      - "127.0.0.1:54545:54545"
      - "127.0.0.1:51121:51121"
      - "127.0.0.1:11451:11451"
    volumes:
      - ./config.yaml:/CLIProxyAPI/config.yaml
      - ./data:/data
      - ./auths:/root/.cli-proxy-api
      - ./logs:/CLIProxyAPI/logs
    networks:
      - noaul-cpa
"@)
    }

    if ($includeKeeper) {
        $keeperBaseUrl = 'http://host.docker.internal:8317'
        $depends = ''
        if ($includeCpa) {
            $keeperBaseUrl = 'http://cli-proxy-api:8317'
            $depends = @"
    depends_on:
      - cli-proxy-api
"@
        }

        $safeKeeperUrl = ConvertTo-YamlScalar $keeperBaseUrl
        $serviceBlocks.Add(@"
  cpa-usage-keeper:
    image: ghcr.io/willxup/cpa-usage-keeper:latest
    pull_policy: always
    container_name: cpa-usage-keeper
    restart: unless-stopped
$depends    environment:
      TZ: `${TZ:-Asia/Shanghai}
      GIN_MODE: release
      CPA_BASE_URL: $safeKeeperUrl
      CPA_MANAGEMENT_KEY: `${CPA_MANAGEMENT_KEY}
      AUTH_ENABLED: "true"
      LOGIN_PASSWORD: `${KEEPER_LOGIN_PASSWORD}
      WORK_DIR: /data
    ports:
      - "127.0.0.1:`${KEEPER_HOST_PORT:-18088}:8080"
    volumes:
      - ./keeper-data:/data
    networks:
      - noaul-cpa
"@)
    }

    $composeContent = @"
services:
$($serviceBlocks -join "`n")

networks:
  noaul-cpa:
    driver: bridge
"@
    $created.Add((Write-NoaulTextFile -Path (Join-Path $stackDir 'docker-compose.yml') -Content $composeContent))
    $created
}

function New-NoaulSub2ApiFiles {
    param(
        [Parameter(Mandatory)]
        [string] $InstallRoot,
        [hashtable] $Secrets = @{}
    )

    $serviceDir = Join-Path $InstallRoot 'services/sub2api'
    New-NoaulDirectory -Path $serviceDir

    $postgresPassword = Get-NoaulSecretValue -Secrets $Secrets -Name 'Sub2ApiPostgresPassword' -Bytes 32
    $jwtSecret = Get-NoaulSecretValue -Secrets $Secrets -Name 'Sub2ApiJwtSecret' -Bytes 32
    $totpKey = Get-NoaulSecretValue -Secrets $Secrets -Name 'Sub2ApiTotpKey' -Bytes 32
    $adminPassword = Get-NoaulSecretValue -Secrets $Secrets -Name 'Sub2ApiAdminPassword' -Bytes 24
    $created = New-Object System.Collections.Generic.List[object]

    $envContent = @"
TZ=Asia/Shanghai
BIND_HOST=127.0.0.1
SERVER_PORT=8081
SERVER_MODE=release
RUN_MODE=standard
POSTGRES_USER=sub2api
POSTGRES_PASSWORD=$postgresPassword
POSTGRES_DB=sub2api
REDIS_PASSWORD=
REDIS_DB=0
ADMIN_EMAIL=admin@sub2api.local
ADMIN_PASSWORD=$adminPassword
JWT_SECRET=$jwtSecret
TOTP_ENCRYPTION_KEY=$totpKey
JWT_EXPIRE_HOUR=24
SECURITY_URL_ALLOWLIST_ENABLED=false
SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP=true
SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS=true
"@
    $created.Add((Write-NoaulTextFile -Path (Join-Path $serviceDir '.env') -Content $envContent))

    $composeContent = @"
services:
  sub2api:
    image: weishaw/sub2api:latest
    container_name: sub2api
    restart: unless-stopped
    ports:
      - "`${BIND_HOST:-127.0.0.1}:`${SERVER_PORT:-8081}:8080"
    volumes:
      - sub2api_data:/app/data
    environment:
      - AUTO_SETUP=true
      - SERVER_HOST=0.0.0.0
      - SERVER_PORT=8080
      - SERVER_MODE=`${SERVER_MODE:-release}
      - RUN_MODE=`${RUN_MODE:-standard}
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USER=`${POSTGRES_USER:-sub2api}
      - DATABASE_PASSWORD=`${POSTGRES_PASSWORD}
      - DATABASE_DBNAME=`${POSTGRES_DB:-sub2api}
      - DATABASE_SSLMODE=disable
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=`${REDIS_PASSWORD:-}
      - REDIS_DB=`${REDIS_DB:-0}
      - ADMIN_EMAIL=`${ADMIN_EMAIL:-admin@sub2api.local}
      - ADMIN_PASSWORD=`${ADMIN_PASSWORD}
      - JWT_SECRET=`${JWT_SECRET}
      - JWT_EXPIRE_HOUR=`${JWT_EXPIRE_HOUR:-24}
      - TOTP_ENCRYPTION_KEY=`${TOTP_ENCRYPTION_KEY}
      - TZ=`${TZ:-Asia/Shanghai}
      - SECURITY_URL_ALLOWLIST_ENABLED=`${SECURITY_URL_ALLOWLIST_ENABLED:-false}
      - SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP=`${SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP:-true}
      - SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS=`${SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS:-true}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - sub2api-network
    healthcheck:
      test: ["CMD", "wget", "-q", "-T", "5", "-O", "/dev/null", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  postgres:
    image: postgres:18-alpine
    container_name: sub2api-postgres
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - PGDATA=/var/lib/postgresql/data
      - POSTGRES_USER=`${POSTGRES_USER:-sub2api}
      - POSTGRES_PASSWORD=`${POSTGRES_PASSWORD}
      - POSTGRES_DB=`${POSTGRES_DB:-sub2api}
      - TZ=`${TZ:-Asia/Shanghai}
    networks:
      - sub2api-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U `${POSTGRES_USER:-sub2api} -d `${POSTGRES_DB:-sub2api}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    image: redis:8-alpine
    container_name: sub2api-redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
    command: >
      sh -c '
        redis-server
        --save 60 1
        --appendonly yes
        --appendfsync everysec
        `${REDIS_PASSWORD:+--requirepass "`$REDIS_PASSWORD"}'
    environment:
      - TZ=`${TZ:-Asia/Shanghai}
    networks:
      - sub2api-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 5s

volumes:
  sub2api_data:
    driver: local
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  sub2api-network:
    driver: bridge
"@
    $created.Add((Write-NoaulTextFile -Path (Join-Path $serviceDir 'docker-compose.yml') -Content $composeContent))
    $created
}

function New-NoaulDockerServiceFiles {
    param(
        [Parameter(Mandatory)]
        [string[]] $Services,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [hashtable] $Secrets = @{}
    )

    $valid = @('cpa', 'cpa-usage-keeper', 'sub2api')
    foreach ($service in @($Services)) {
        if ($valid -notcontains $service) {
            throw "Unknown Docker service: $service"
        }
    }

    $created = New-Object System.Collections.Generic.List[object]
    $cpaServices = @($Services | Where-Object { $_ -in @('cpa', 'cpa-usage-keeper') })
    if ($cpaServices.Count -gt 0) {
        $files = New-NoaulCpaStackFiles -Services $cpaServices -InstallRoot $InstallRoot -Secrets $Secrets
        foreach ($file in $files) {
            $created.Add($file)
        }
    }

    if ($Services -contains 'sub2api') {
        $files = New-NoaulSub2ApiFiles -InstallRoot $InstallRoot -Secrets $Secrets
        foreach ($file in $files) {
            $created.Add($file)
        }
    }

    $created
}

function Start-NoaulDockerServices {
    param(
        [Parameter(Mandatory)][string[]] $Services,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [switch] $DryRun
    )

    if ($Services.Count -eq 0) {
        return
    }

    if ($DryRun) {
        Write-Host "[dry-run] generate Docker service files under $InstallRoot"
        foreach ($service in $Services) {
            Write-Host "[dry-run] select Docker service: $service"
        }
        Write-Host '[dry-run] docker compose pull'
        Write-Host '[dry-run] docker compose up -d'
        return
    }

    if (-not (Test-NoaulCommand -Name 'docker')) {
        throw 'docker was not found. Install and start Docker Desktop first, then rerun Noaul.'
    }

    $created = New-NoaulDockerServiceFiles -Services $Services -InstallRoot $InstallRoot
    Write-Host "Generated Docker files:"
    foreach ($file in $created) {
        Write-Host "  $($file.Path)"
    }

    $composeDirs = @()
    if (@($Services | Where-Object { $_ -in @('cpa', 'cpa-usage-keeper') }).Count -gt 0) {
        $composeDirs += (Join-Path $InstallRoot 'services/cpa-stack')
    }
    if ($Services -contains 'sub2api') {
        $composeDirs += (Join-Path $InstallRoot 'services/sub2api')
    }

    foreach ($composeDir in $composeDirs) {
        Push-Location $composeDir
        try {
            Invoke-NoaulCommand -Display "docker compose pull in $composeDir" -ScriptBlock { & docker compose pull }
            Invoke-NoaulCommand -Display "docker compose up -d in $composeDir" -ScriptBlock { & docker compose up -d }
        }
        finally {
            Pop-Location
        }
    }
}

function Update-NoaulDockerServices {
    param(
        [Parameter(Mandatory)][string[]] $Services,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [switch] $DryRun
    )

    if ($Services.Count -eq 0) {
        return
    }

    if ($DryRun) {
        foreach ($service in $Services) {
            Write-Host "[dry-run] update installed Docker service: $service"
        }
        Write-Host '[dry-run] docker compose pull'
        Write-Host '[dry-run] docker compose up -d'
        return
    }

    if (-not (Test-NoaulCommand -Name 'docker')) {
        throw 'docker was not found. Start Docker Desktop first, then rerun Noaul.'
    }

    $composeDirs = @()
    if (@($Services | Where-Object { $_ -in @('cpa', 'cpa-usage-keeper') }).Count -gt 0) {
        $composeDirs += (Join-Path $InstallRoot 'services/cpa-stack')
    }
    if ($Services -contains 'sub2api') {
        $composeDirs += (Join-Path $InstallRoot 'services/sub2api')
    }

    foreach ($composeDir in @($composeDirs | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath (Join-Path $composeDir 'docker-compose.yml'))) {
            throw "Docker compose file was not found in $composeDir. Install the service first, then rerun update."
        }

        Push-Location $composeDir
        try {
            Invoke-NoaulCommand -Display "docker compose pull in $composeDir" -ScriptBlock { & docker compose pull }
            Invoke-NoaulCommand -Display "docker compose up -d in $composeDir" -ScriptBlock { & docker compose up -d }
        }
        finally {
            Pop-Location
        }
    }
}

# --- Noaul.UI.psm1 ---
function Read-NoaulYesNo {
    param(
        [Parameter(Mandatory)][string] $Prompt,
        [bool] $Default = $false
    )

    $suffix = if ($Default) { '[Y/n]' } else { '[y/N]' }
    while ($true) {
        $answer = Read-Host "$Prompt $suffix"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default
        }

        switch -Regex ($answer.Trim()) {
            '^(y|yes)$' { return $true }
            '^(n|no)$' { return $false }
            default { Write-Host 'Please answer y or n.' }
        }
    }
}

function Read-NoaulInstallMode {
    while ($true) {
        $answer = Read-Host 'Choose action: install new tools or update installed tools? [i/U]'
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return 'update'
        }

        switch -Regex ($answer.Trim()) {
            '^(i|install)$' { return 'install' }
            '^(u|update)$' { return 'update' }
            default { Write-Host 'Please answer install or update.' }
        }
    }
}

function Select-NoaulComponentsInteractive {
    $selected = New-Object System.Collections.Generic.List[string]
    $catalog = @(Get-NoaulComponentCatalog)
    $categories = @(
        'Package Manager',
        'Core Dev',
        'Runtime',
        'Node Tooling',
        'Python Tooling',
        'Build Tools',
        'Shell',
        'Editor',
        'Docker Runtime',
        'AI CLI',
        'AI App',
        'Docker Service'
    )

    foreach ($category in $categories) {
        $items = @($catalog | Where-Object { $_.Category -eq $category })
        if ($items.Count -eq 0) {
            continue
        }

        Write-Host ''
        Write-Host "== $category =="
        foreach ($component in $items) {
            $question = "$($component.Name) [$($component.Id)] - $($component.Description)"
            if (Read-NoaulYesNo -Prompt $question -Default:$component.DefaultSelected) {
                $selected.Add($component.Id)
            }
        }
    }

    $selected.ToArray()
}

function Show-NoaulPlan {
    param(
        [Parameter(Mandatory)][pscustomobject[]] $Plan,
        [string] $Mode = 'install',
        [string] $Platform = (Get-NoaulCurrentPlatform)
    )

    Write-Host ''
    if ($Mode -eq 'update') {
        Write-Host 'Update plan:'
    }
    else {
        Write-Host 'Install/update plan:'
    }
    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        Write-Host ("  - {0} ({1}) via {2}" -f $component.Name, $component.Id, $installMethod)
    }
}

function Start-Noaul {
    param(
        [string[]] $Install = @(),
        [string[]] $DockerService = @(),
        [switch] $NoPrompt,
        [switch] $DryRun,
        [switch] $Update,
        [switch] $ListComponents,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $NoLogo
    )

    if ($ListComponents) {
        Get-NoaulComponentCatalog |
            Select-Object Id, Name, Category, DefaultSelected, InstallMethod, Package |
            Format-Table -AutoSize
        return
    }

    if (-not $NoLogo) {
        Write-Host 'Noaul Windows guided installer'
        Write-Host 'Choose install to add tools, or update to refresh only tools already installed.'
    }

    $selected = New-Object System.Collections.Generic.List[string]
    foreach ($item in @(ConvertTo-NoaulComponentIds -Components $Install)) {
        $selected.Add($item)
    }
    foreach ($service in @(ConvertTo-NoaulComponentIds -Components $DockerService)) {
        $selected.Add($service)
    }

    $mode = if ($Update) { 'update' } else { 'install' }
    if (-not $NoPrompt -and $selected.Count -eq 0) {
        $mode = Read-NoaulInstallMode
    }

    if ($mode -eq 'install' -and -not $NoPrompt -and $selected.Count -eq 0) {
        foreach ($item in (Select-NoaulComponentsInteractive)) {
            $selected.Add($item)
        }
    }

    if ($mode -eq 'update') {
        $plan = @(New-NoaulUpdatePlan -Components $selected.ToArray() -InstallRoot $InstallRoot -Platform $Platform)
    }
    else {
        $plan = @(New-NoaulInstallPlan -Components $selected.ToArray() -IncludeRecommendedCore:(!$NoPrompt) -Platform $Platform)
    }

    if ($plan.Count -eq 0) {
        if ($mode -eq 'update') {
            Write-Host 'No installed Noaul components were detected for update.'
        }
        else {
            Write-Host 'Nothing selected.'
        }
        return
    }

    Show-NoaulPlan -Plan $plan -Mode $mode -Platform $Platform
    if (-not $NoPrompt) {
        if (-not (Read-NoaulYesNo -Prompt 'Proceed with this plan?' -Default:$false)) {
            Write-Host 'Cancelled.'
            return
        }
    }

    if ($mode -eq 'update') {
        Invoke-NoaulUpdatePlan -Plan $plan -InstallRoot $InstallRoot -Platform $Platform -DryRun:$DryRun
    }
    else {
        Invoke-NoaulInstallPlan -Plan $plan -InstallRoot $InstallRoot -Platform $Platform -DryRun:$DryRun
    }
}

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
