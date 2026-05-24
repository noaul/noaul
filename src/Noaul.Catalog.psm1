Set-StrictMode -Version Latest

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

Export-ModuleMember -Function `
    Get-NoaulDefaultInstallRoot, `
    Get-NoaulUserHome, `
    Join-NoaulOptionalPath, `
    Get-NoaulPathHints, `
    Get-NoaulComponentCatalog, `
    Get-NoaulComponentById, `
    ConvertTo-NoaulComponentIds, `
    Get-NoaulCurrentPlatform, `
    Resolve-NoaulComponentInstallMethod, `
    Resolve-NoaulComponentPackage
