BeforeAll {
    $ErrorActionPreference = 'Stop'
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:ModulePath = Join-Path $script:RepoRoot 'src/Noaul.psm1'
    Import-Module $script:ModulePath -Force
}

Describe 'Wrapper Smoke Test' {
    It 'install.ps1 resolves module and runs entry point' {
        $installPath = Join-Path $script:RepoRoot 'install.ps1'
        $script = Get-Content -LiteralPath $installPath -Raw
        $escapedModulePath = $script:ModulePath.Replace("'", "''")
        $escapedRepoRoot = $script:RepoRoot.Replace("'", "''")

        # Replace the entire Resolve-NoaulModulePath function body with a simple local copy
        $script = $script -replace "(?s)function Resolve-NoaulModulePath \{.*?\r?\n\}", @"
function Resolve-NoaulModulePath {
    '$escapedModulePath'
}
"@
        $script = $script.Replace('Start-Noaul @startArgs', 'Write-Output "NOAUL_WRAPPER_SMOKE:$modulePath"')

        $command = @"
`$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath '$escapedRepoRoot'
Invoke-Expression @'
$script
'@
"@
        $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))
        $output = & pwsh -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded

        $LASTEXITCODE | Should -Be 0 -Because 'install.ps1 should run without errors'
        ($output -join "`n") | Should -Match 'NOAUL_WRAPPER_SMOKE:.*[Nn]oaul\.psm1'
    }
}

Describe 'Linux Shell Installer' {
    BeforeAll {
        $script:LinuxInstallPath = Join-Path $script:RepoRoot 'install.sh'
    }

    It 'Provides a bash entry point for Linux users' {
        Test-Path -LiteralPath $script:LinuxInstallPath | Should -BeTrue
        $content = Get-Content -LiteralPath $script:LinuxInstallPath -Raw
        $content | Should -Match '#!/usr/bin/env bash'
        $content | Should -Match 'set -euo pipefail'
    }

    It 'Defaults to cc-switch and uses saladday/cc-switch-cli' {
        $content = Get-Content -LiteralPath $script:LinuxInstallPath -Raw
        $content | Should -Match 'cc-switch'
        $content | Should -Match 'saladday/cc-switch-cli/releases/latest/download/install.sh'
        $content | Should -Match 'CC_SWITCH_FORCE'
    }
}

Describe 'Component Catalog' {
    BeforeAll {
        $script:Catalog = Get-NoaulComponentCatalog
        $script:Ids = @($script:Catalog | ForEach-Object { $_.Id })
    }

    Context 'Completeness' {
        It 'Contains <Id>' -TestCases @(
            @{ Id = 'winget' }
            @{ Id = 'scoop' }
            @{ Id = 'git' }
            @{ Id = 'curl' }
            @{ Id = '7zip' }
            @{ Id = 'ripgrep' }
            @{ Id = 'fd' }
            @{ Id = 'jq' }
            @{ Id = 'gh' }
            @{ Id = 'git-lfs' }
            @{ Id = 'nodejs' }
            @{ Id = 'npm' }
            @{ Id = 'pnpm' }
            @{ Id = 'python' }
            @{ Id = 'uv' }
            @{ Id = 'pipx' }
            @{ Id = 'ruff' }
            @{ Id = 'visual-build-tools' }
            @{ Id = 'powershell' }
            @{ Id = 'vscode' }
            @{ Id = 'docker-desktop' }
            @{ Id = 'codex' }
            @{ Id = 'claude-code' }
            @{ Id = 'kiro' }
            @{ Id = 'opencode' }
            @{ Id = 'cc-switch' }
            @{ Id = 'cpa' }
            @{ Id = 'cpa-usage-keeper' }
            @{ Id = 'sub2api' }
        ) {
            $script:Ids | Should -Contain $Id
        }

        It 'Does not contain windows-terminal' {
            $script:Ids | Should -Not -Contain 'windows-terminal'
        }
    }

    Context 'Schema consistency' {
        It 'All components have required properties' {
            $required = @('Id', 'Name', 'Category', 'DefaultSelected', 'InstallMethod', 'LinuxInstallMethod', 'Package', 'LinuxPackage', 'Command', 'Requires', 'Description')
            foreach ($c in $script:Catalog) {
                foreach ($prop in $required) {
                    $c.PSObject.Properties.Name | Should -Contain $prop -Because "$($c.Id) should have $prop"
                }
            }
        }
    }

    Context 'Component properties' {
        It 'npm is modeled as virtual' {
            $npm = $script:Catalog | Where-Object { $_.Id -eq 'npm' } | Select-Object -First 1
            $npm.InstallMethod | Should -Be 'virtual'
        }

        It 'winget is bootstrapped instead of only detected' {
            $winget = $script:Catalog | Where-Object { $_.Id -eq 'winget' } | Select-Object -First 1
            $winget.InstallMethod | Should -Be 'bootstrap-winget'
            $winget.DefaultSelected | Should -BeTrue
        }

        It 'scoop remains default-selected for bootstrap' {
            $scoop = $script:Catalog | Where-Object { $_.Id -eq 'scoop' } | Select-Object -First 1
            $scoop.InstallMethod | Should -Be 'bootstrap-scoop'
            $scoop.DefaultSelected | Should -BeTrue
        }

        It 'cc-switch uses winget on Windows and cc-switch-cli on Linux' {
            $cc = $script:Catalog | Where-Object { $_.Id -eq 'cc-switch' } | Select-Object -First 1
            $cc.InstallMethod | Should -Be 'winget'
            $cc.LinuxInstallMethod | Should -Be 'cc-switch-cli'
            $cc.LinuxPackage | Should -Match 'saladday/cc-switch-cli'
        }

        It 'AI CLIs and Docker services are not default-selected' {
            $optionalIds = @($script:Catalog | Where-Object {
                $_.Category -in @('AI CLI', 'Docker Service') -and $_.DefaultSelected
            } | ForEach-Object { $_.Id })
            $optionalIds.Count | Should -Be 0
        }
    }
}

Describe 'Windows PowerShell Compatibility' {
    It 'Detects Windows without relying on PowerShell 7 platform variables' {
        $windowsPowerShell = Get-Command powershell -ErrorAction SilentlyContinue
        if (-not $windowsPowerShell) {
            Set-ItResult -Skipped -Because 'Windows PowerShell is not available on this machine'
            return
        }

        $escapedModulePath = $script:ModulePath.Replace("'", "''")
        $command = @"
`$ErrorActionPreference = 'Continue'
Import-Module '$escapedModulePath' -Force
Get-NoaulCurrentPlatform
"@
        $output = & $windowsPowerShell.Source -NoProfile -ExecutionPolicy Bypass -Command $command *>&1

        ($output -join "`n") | Should -Not -Match 'VariableIsUndefined|\$IsLinux|\$IsMacOS'
        ($output | Select-Object -Last 1) | Should -Be 'windows'
    }
}

Describe 'Install Plan' {
    Context 'Dependency resolution' {
        It 'codex requires nodejs and npm' {
            $plan = New-NoaulInstallPlan -Components @('codex') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'scoop'
            $planIds | Should -Contain 'nodejs'
            $planIds | Should -Contain 'npm'
            $planIds | Should -Contain 'codex'
        }

        It 'codex does not pull in claude-code, opencode, or kiro' {
            $plan = New-NoaulInstallPlan -Components @('codex', 'cc-switch') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Not -Contain 'claude-code'
            $planIds | Should -Not -Contain 'opencode'
            $planIds | Should -Not -Contain 'kiro'
        }

        It 'pnpm, uv, ruff pull in their prerequisites' {
            $plan = New-NoaulInstallPlan -Components @('pnpm', 'uv', 'ruff') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'scoop'
            $planIds | Should -Contain 'nodejs'
            $planIds | Should -Contain 'npm'
            $planIds | Should -Contain 'python'
            $planIds | Should -Contain 'uv'
            $planIds | Should -Contain 'pnpm'
            $planIds | Should -Contain 'ruff'
        }

        It 'sub2api pulls in docker-desktop' {
            $plan = New-NoaulInstallPlan -Components @('sub2api') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'winget'
            $planIds | Should -Contain 'docker-desktop'
        }

        It 'winget-installed components verify winget before installing' {
            $plan = New-NoaulInstallPlan -Components @('cc-switch') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'winget'
            $planIds | Should -Contain 'cc-switch'
            [array]::IndexOf($planIds, 'winget') | Should -BeLessThan ([array]::IndexOf($planIds, 'cc-switch'))
        }

        It 'Linux cc-switch install plan does not add Windows package managers' {
            $plan = New-NoaulInstallPlan -Components @('cc-switch') -IncludeRecommendedCore:$false -Platform linux
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'cc-switch'
            $planIds | Should -Not -Contain 'winget'
            $planIds | Should -Not -Contain 'scoop'
        }

        It 'default plan includes recommended core components' {
            $plan = New-NoaulInstallPlan -Components @() -IncludeRecommendedCore:$true
            $planIds = @($plan | ForEach-Object { $_.Id })
            foreach ($comp in @('winget', 'scoop', 'git', 'curl', 'nodejs', 'npm', 'python', 'uv')) {
                $planIds | Should -Contain $comp -Because "default plan should include $comp"
            }
        }

        It 'Unknown component throws' {
            { New-NoaulInstallPlan -Components @('nonexistent-tool') -IncludeRecommendedCore:$false } | Should -Throw
        }

        It 'No infinite loop with multiple AI CLIs' {
            $plan = New-NoaulInstallPlan -Components @('codex', 'claude-code', 'opencode') -IncludeRecommendedCore:$false
            $plan | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Comma-separated input' {
        It 'Splits codex,cc-switch into both components' {
            $plan = New-NoaulInstallPlan -Components @('codex,cc-switch') -IncludeRecommendedCore:$false
            $planIds = @($plan | ForEach-Object { $_.Id })
            $planIds | Should -Contain 'codex'
            $planIds | Should -Contain 'cc-switch'
        }
    }
}

Describe 'Prompt Defaults' {
    BeforeAll {
        $script:UiSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'src/Noaul.UI.psm1') -Raw
    }

    It 'Shows uppercase Y and N in yes-no prompts' {
        $script:UiSource | Should -Match "\[Y/N\]"
        $script:UiSource.Contains('[Y/n]') | Should -BeFalse
        $script:UiSource.Contains('[y/N]') | Should -BeFalse
        $script:UiSource | Should -Match 'Please answer Y or N\.'
    }

    It 'Shows uppercase I and U in install/update prompt' {
        $script:UiSource | Should -Match '\[I/U\]'
        $script:UiSource.Contains('[i/U]') | Should -BeFalse
        $script:UiSource.Contains('[I/u]') | Should -BeFalse
    }

    It 'Defaults final plan confirmation to yes when Enter is pressed' {
        $script:UiSource | Should -Match 'Read-NoaulYesNo -Prompt ''Proceed with this plan\?'' -Default:\$true'
    }
}

Describe 'Windows Package Manager Bootstrap' {
    BeforeAll {
        $script:CatalogSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'src/Noaul.Catalog.psm1') -Raw
        $script:InstallerSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'src/Noaul.Installer.psm1') -Raw
        $script:WrapperSource = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'install.ps1') -Raw
    }

    It 'Downloads App Installer dependencies when bootstrapping winget' {
        $script:InstallerSource | Should -Match 'function Install-NoaulWinget'
        $script:InstallerSource | Should -Match 'Microsoft\.VCLibs\.x64\.14\.00\.Desktop\.appx'
        $script:InstallerSource | Should -Match 'Microsoft\.UI\.Xaml/2\.8\.6'
        $script:InstallerSource | Should -Match 'Microsoft\.DesktopAppInstaller_8wekyb3d8bbwe\.msixbundle'
        $script:InstallerSource | Should -Match 'Add-AppxPackage'
    }

    It 'Allows Scoop bootstrap from an elevated PowerShell session' {
        $script:InstallerSource | Should -Match 'Test-NoaulElevated'
        $script:InstallerSource | Should -Match '-RunAsAdmin'
    }

    It 'Keeps installing remaining plan items after a component failure' {
        $script:InstallerSource | Should -Match 'Invoke-NoaulPlanStep'
        $script:InstallerSource | Should -Match 'Noaul completed with'
    }

    It 'Runs a post-install health check after install and update plans' {
        $script:InstallerSource | Should -Match 'function Test-NoaulPlanHealth'
        $script:InstallerSource | Should -Match 'function Write-NoaulPlanHealthSummary'
        $script:InstallerSource | Should -Match 'Test-NoaulPlanHealth -Plan \$Plan'
        $script:InstallerSource | Should -Match 'Post-install check:'
    }

    It 'Sets process execution policy before importing the downloaded module' {
        $script:WrapperSource | Should -Match 'Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass'
        $script:WrapperSource.IndexOf('Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass') |
            Should -BeLessThan $script:WrapperSource.IndexOf('Import-Module $modulePath -Force')
    }
}

Describe 'Update Plan' {
    It 'Includes installed components and respects filter' {
        $plan = New-NoaulUpdatePlan -InstalledComponentIds @('winget', 'scoop', 'git', 'nodejs', 'npm', 'python', 'codex')
        $planIds = @($plan | ForEach-Object { $_.Id })
        foreach ($comp in @('winget', 'scoop', 'git', 'nodejs', 'npm', 'python', 'codex')) {
            $planIds | Should -Contain $comp
        }
        foreach ($comp in @('curl', 'uv', 'pnpm', 'claude-code', 'docker-desktop')) {
            $planIds | Should -Not -Contain $comp
        }
    }

    It 'Empty installed list produces empty plan' {
        $plan = @(New-NoaulUpdatePlan -InstalledComponentIds @())
        $plan.Count | Should -Be 0
    }
}

Describe 'Dry-run execution' {
    It 'Install plan dry-run succeeds' {
        $plan = New-NoaulInstallPlan -Components @('codex', 'cc-switch') -IncludeRecommendedCore:$false
        { Invoke-NoaulInstallPlan -Plan $plan -DryRun -InstallRoot (Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-dry-run-test') } | Should -Not -Throw
    }

    It 'Update plan dry-run succeeds' {
        $plan = New-NoaulInstallPlan -Components @('pnpm', 'uv', 'ruff') -IncludeRecommendedCore:$false
        { Invoke-NoaulInstallPlan -Plan $plan -DryRun -InstallRoot (Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-tooling-dry-run-test') } | Should -Not -Throw
    }

    It 'cc-switch dry-run on Linux succeeds' {
        $cc = Get-NoaulComponentCatalog | Where-Object { $_.Id -eq 'cc-switch' }
        { Invoke-NoaulInstallPlan -Plan @($cc) -DryRun -Platform linux } | Should -Not -Throw
        { Invoke-NoaulUpdatePlan -Plan @($cc) -DryRun -Platform linux } | Should -Not -Throw
    }
}

Describe 'Docker Service Files' {
    BeforeAll {
        $script:TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('noaul-tests-' + [guid]::NewGuid().ToString('N'))
        $script:Secrets = @{
            CpaManagementKey = 'test-management-key'
            KeeperLoginPassword = 'test-login-password'
            Sub2ApiPostgresPassword = 'test-postgres-password'
            Sub2ApiJwtSecret = 'test-jwt-secret'
            Sub2ApiTotpKey = 'test-totp-key'
        }
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:TempRoot) {
            Remove-Item -LiteralPath $script:TempRoot -Recurse -Force
        }
    }

    It 'Generates CPA stack files with correct content' {
        New-NoaulDockerServiceFiles -Services @('cpa', 'cpa-usage-keeper') -InstallRoot $script:TempRoot -Secrets $script:Secrets | Out-Null

        $cpaCompose = Get-Content -LiteralPath (Join-Path $script:TempRoot 'services/cpa-stack/docker-compose.yml') -Raw
        $cpaEnv = Get-Content -LiteralPath (Join-Path $script:TempRoot 'services/cpa-stack/.env') -Raw

        $cpaCompose | Should -Match 'eceasy/cli-proxy-api:latest'
        $cpaCompose | Should -Match 'ghcr.io/willxup/cpa-usage-keeper:latest'
        $cpaCompose | Should -Match 'CPA_MANAGEMENT_KEY'
        $cpaEnv | Should -Match 'test-management-key'
    }

    It 'Generates Sub2API files with correct content' {
        New-NoaulDockerServiceFiles -Services @('sub2api') -InstallRoot $script:TempRoot -Secrets $script:Secrets | Out-Null

        $sub2apiCompose = Get-Content -LiteralPath (Join-Path $script:TempRoot 'services/sub2api/docker-compose.yml') -Raw
        $sub2apiEnv = Get-Content -LiteralPath (Join-Path $script:TempRoot 'services/sub2api/.env') -Raw

        $sub2apiCompose | Should -Match 'weishaw/sub2api:latest'
        $sub2apiCompose | Should -Match 'postgres:18-alpine'
        $sub2apiCompose | Should -Match 'redis:8-alpine'
        $sub2apiEnv | Should -Match 'test-postgres-password'
    }

    It 'Unknown Docker service throws' {
        { New-NoaulDockerServiceFiles -Services @('nonexistent') -InstallRoot $script:TempRoot } | Should -Throw
    }
}

Describe 'YAML Scalar Safety' {
    It 'Quotes values with special characters' {
        ConvertTo-YamlScalar 'simple' | Should -Be 'simple'
        ConvertTo-YamlScalar 'has:colon' | Should -Match '^"'
        ConvertTo-YamlScalar 'has#hash' | Should -Match '^"'
        ConvertTo-YamlScalar 'has"quote' | Should -Match '^"'
    }
}
