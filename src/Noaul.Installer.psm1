Set-StrictMode -Version Latest

$script:ModuleRoot = $PSScriptRoot
Import-Module (Join-Path $script:ModuleRoot 'Noaul.Catalog.psm1') -Force

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
    $global:LASTEXITCODE = $null
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
        'bootstrap-winget' {
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

function Test-NoaulElevated {
    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Install-NoaulWinget {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [switch] $DryRun
    )

    Update-NoaulCurrentPath
    if (Test-NoaulCommand -Name 'winget') {
        Write-Host '[skip] Windows Package Manager is already available (winget)'
        return
    }

    if ($DryRun) {
        Write-Host '[dry-run] install Windows Package Manager from Microsoft winget-cli release'
        return
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-winget-bootstrap'
    $vclibsPath = Join-Path $tempRoot 'Microsoft.VCLibs.x64.appx'
    $uiXamlZip = Join-Path $tempRoot 'Microsoft.UI.Xaml.2.8.6.zip'
    $uiXamlDir = Join-Path $tempRoot 'Microsoft.UI.Xaml.2.8.6'
    $appInstallerPath = Join-Path $tempRoot 'Microsoft.DesktopAppInstaller.msixbundle'

    Invoke-NoaulCommand -Display 'install Windows Package Manager without Microsoft Store' -ScriptBlock {
        New-NoaulDirectory -Path $tempRoot | Out-Null

        Invoke-WebRequest -UseBasicParsing -Uri 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -OutFile $vclibsPath
        Invoke-WebRequest -UseBasicParsing -Uri 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6' -OutFile $uiXamlZip
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -OutFile $appInstallerPath

        if (Test-Path -LiteralPath $uiXamlDir) {
            Remove-Item -LiteralPath $uiXamlDir -Recurse -Force
        }
        Expand-Archive -LiteralPath $uiXamlZip -DestinationPath $uiXamlDir -Force
        $uiXamlPackage = Get-ChildItem -LiteralPath (Join-Path $uiXamlDir 'tools\AppX\x64\Release') -Filter '*.appx' |
            Select-Object -First 1
        if (-not $uiXamlPackage) {
            throw 'Microsoft.UI.Xaml appx package was not found after extraction.'
        }

        Add-AppxPackage -Path $vclibsPath
        Add-AppxPackage -Path $uiXamlPackage.FullName
        Add-AppxPackage -Path $appInstallerPath
    }

    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'winget')) {
        $windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
        if ((Test-Path -LiteralPath $windowsApps) -and ($env:Path -notlike "*$windowsApps*")) {
            $env:Path = "$env:Path;$windowsApps"
        }
    }
    if (-not (Test-NoaulCommand -Name 'winget')) {
        throw 'winget was installed or repaired, but winget was still not found on PATH. Reopen PowerShell and rerun Noaul.'
    }
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

    $installerPath = Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-install-scoop.ps1'
    Invoke-NoaulCommand -Display 'install Scoop package manager from get.scoop.sh' -ScriptBlock {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://get.scoop.sh' -OutFile $installerPath
        $scoopArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installerPath)
        if (Test-NoaulElevated) {
            $scoopArgs += '-RunAsAdmin'
        }
        & powershell @scoopArgs
    }
    Update-NoaulCurrentPath
    if (-not (Test-NoaulCommand -Name 'scoop')) {
        throw 'Scoop installer completed, but scoop was still not found on PATH. Reopen PowerShell and rerun Noaul.'
    }
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

function Invoke-NoaulPlanStep {
    param(
        [Parameter(Mandatory)][pscustomobject] $Component,
        [Parameter(Mandatory)][string] $InstallMethod,
        [Parameter(Mandatory)][string] $Action,
        [Parameter(Mandatory)][scriptblock] $ScriptBlock
    )

    try {
        & $ScriptBlock
        return $null
    }
    catch {
        $message = $_.Exception.Message
        Write-Warning ("[{0}] {1} ({2}) failed via {3}: {4}" -f $Action, $Component.Name, $Component.Id, $InstallMethod, $message)
        return [pscustomobject]@{
            Id = [string] $Component.Id
            Name = [string] $Component.Name
            Method = $InstallMethod
            Action = $Action
            Error = $message
        }
    }
}

function Write-NoaulPlanFailureSummary {
    param([object[]] $Failures = @())

    $failureCount = @($Failures).Count
    Write-Host ("Noaul completed with {0} failed step(s)." -f $failureCount)
    foreach ($failure in @($Failures)) {
        Write-Host ("  - {0} ({1}) via {2}: {3}" -f $failure.Name, $failure.Id, $failure.Method, $failure.Error)
    }
}

function Test-NoaulPlanHealth {
    param(
        [Parameter(Mandatory)][pscustomobject[]] $Plan,
        [string] $InstallRoot = (Get-NoaulDefaultInstallRoot),
        [string] $Platform = (Get-NoaulCurrentPlatform),
        [switch] $DryRun
    )

    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        if ($DryRun) {
            [pscustomobject]@{
                Id = [string] $component.Id
                Name = [string] $component.Name
                Method = $installMethod
                Healthy = $null
                Status = 'dry-run'
                Details = 'not checked during dry run'
            }
            continue
        }

        try {
            $healthy = Test-NoaulComponentInstalled -Component $component -InstallRoot $InstallRoot -Platform $Platform
            [pscustomobject]@{
                Id = [string] $component.Id
                Name = [string] $component.Name
                Method = $installMethod
                Healthy = [bool] $healthy
                Status = if ($healthy) { 'ok' } else { 'failed' }
                Details = if ($healthy) { 'detected' } else { 'not detected after install/update' }
            }
        }
        catch {
            [pscustomobject]@{
                Id = [string] $component.Id
                Name = [string] $component.Name
                Method = $installMethod
                Healthy = $false
                Status = 'failed'
                Details = $_.Exception.Message
            }
        }
    }
}

function Write-NoaulPlanHealthSummary {
    param([object[]] $Results = @())

    $dryRun = @($Results | Where-Object { $_.Status -eq 'dry-run' })
    if ($dryRun.Count -eq @($Results).Count) {
        Write-Host ("[dry-run] Post-install check: {0} component(s) would be checked." -f $dryRun.Count)
        return
    }

    $ok = @($Results | Where-Object { $_.Healthy -eq $true })
    $failed = @($Results | Where-Object { $_.Healthy -eq $false })
    Write-Host ("Post-install check: {0} OK, {1} failed." -f $ok.Count, $failed.Count)

    foreach ($result in $failed) {
        Write-Warning ("[check] {0} ({1}) via {2}: {3}" -f $result.Name, $result.Id, $result.Method, $result.Details)
    }
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
    $failures = New-Object System.Collections.Generic.List[object]
    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        $failure = Invoke-NoaulPlanStep -Component $component -InstallMethod $installMethod -Action 'install' -ScriptBlock {
            switch ($installMethod) {
                'detect' {
                    Assert-NoaulDetectedTool -Component $component -DryRun:$DryRun
                }
                'bootstrap-winget' {
                    Install-NoaulWinget -Component $component -DryRun:$DryRun
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
        if ($failure) {
            $failures.Add($failure)
        }
    }

    if ($dockerServices.Count -gt 0) {
        $dockerComponent = [pscustomobject]@{
            Id = 'docker-services'
            Name = 'Docker services'
        }
        $failure = Invoke-NoaulPlanStep -Component $dockerComponent -InstallMethod 'docker' -Action 'install' -ScriptBlock {
            Start-NoaulDockerServices -Services $dockerServices -InstallRoot $InstallRoot -DryRun:$DryRun
        }
        if ($failure) {
            $failures.Add($failure)
        }
    }

    Write-NoaulPlanFailureSummary -Failures $failures.ToArray()
    $health = @(Test-NoaulPlanHealth -Plan $Plan -InstallRoot $InstallRoot -Platform $Platform -DryRun:$DryRun)
    Write-NoaulPlanHealthSummary -Results $health
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
    $failures = New-Object System.Collections.Generic.List[object]
    foreach ($component in @($Plan)) {
        $installMethod = Resolve-NoaulComponentInstallMethod -Component $component -Platform $Platform
        $failure = Invoke-NoaulPlanStep -Component $component -InstallMethod $installMethod -Action 'update' -ScriptBlock {
            switch ($installMethod) {
                'detect' {
                    Assert-NoaulDetectedTool -Component $component -DryRun:$DryRun
                }
                'bootstrap-winget' {
                    Install-NoaulWinget -Component $component -DryRun:$DryRun
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
        if ($failure) {
            $failures.Add($failure)
        }
    }

    if ($dockerServices.Count -gt 0) {
        $dockerComponent = [pscustomobject]@{
            Id = 'docker-services'
            Name = 'Docker services'
        }
        $failure = Invoke-NoaulPlanStep -Component $dockerComponent -InstallMethod 'docker' -Action 'update' -ScriptBlock {
            Update-NoaulDockerServices -Services $dockerServices -InstallRoot $InstallRoot -DryRun:$DryRun
        }
        if ($failure) {
            $failures.Add($failure)
        }
    }

    Write-NoaulPlanFailureSummary -Failures $failures.ToArray()
    $health = @(Test-NoaulPlanHealth -Plan $Plan -InstallRoot $InstallRoot -Platform $Platform -DryRun:$DryRun)
    Write-NoaulPlanHealthSummary -Results $health
}

Export-ModuleMember -Function `
    Update-NoaulCurrentPath, `
    New-NoaulInstallPlan, `
    Get-NoaulImplicitPrerequisiteIds, `
    New-NoaulUpdatePlan, `
    New-NoaulSecret, `
    Get-NoaulSecretValue, `
    New-NoaulDirectory, `
    Write-NoaulTextFile, `
    Test-NoaulCommand, `
    Invoke-NoaulCommand, `
    Test-NoaulComponentCommand, `
    Test-NoaulScoopPackageInstalled, `
    Test-NoaulWingetPackageInstalled, `
    Test-NoaulNpmPackageInstalled, `
    Test-NoaulDockerServiceInstalled, `
    Test-NoaulComponentInstalled, `
    Get-NoaulInstalledComponentIds, `
    Assert-NoaulDetectedTool, `
    Test-NoaulElevated, `
    Install-NoaulWinget, `
    Install-NoaulScoop, `
    Install-NoaulScoopPackage, `
    Assert-NoaulVirtualComponent, `
    Set-NoaulCodexDefaultReasoning, `
    Install-NoaulWingetPackage, `
    Update-NoaulWingetPackage, `
    Install-NoaulNpmPackage, `
    Install-NoaulCcSwitchCli, `
    Update-NoaulScoop, `
    Update-NoaulScoopPackage, `
    Update-NoaulNpmPackage, `
    Update-NoaulCcSwitchCli, `
    Invoke-NoaulPlanStep, `
    Write-NoaulPlanFailureSummary, `
    Test-NoaulPlanHealth, `
    Write-NoaulPlanHealthSummary, `
    Invoke-NoaulInstallPlan, `
    Invoke-NoaulUpdatePlan
