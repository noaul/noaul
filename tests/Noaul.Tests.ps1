$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$ModulePath = Join-Path $RepoRoot 'src/Noaul.psm1'

function Assert-True {
    param(
        [bool] $Condition,
        [string] $Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Contains {
    param(
        [object[]] $Items,
        [string] $Expected,
        [string] $Message
    )

    Assert-True -Condition ($Items -contains $Expected) -Message $Message
}

Import-Module $ModulePath -Force

$catalog = Get-NoaulComponentCatalog
$ids = @($catalog | ForEach-Object { $_.Id })

foreach ($required in @(
    'git',
    'nodejs',
    'docker-desktop',
    'codex',
    'claude-code',
    'kiro',
    'opencode',
    'cc-switch',
    'cpa',
    'cpa-usage-keeper',
    'sub2api'
)) {
    Assert-Contains -Items $ids -Expected $required -Message "Catalog should include $required"
}

$optionalIds = @($catalog | Where-Object { $_.Category -in @('AI CLI', 'Docker Service') -and $_.DefaultSelected } | ForEach-Object { $_.Id })
Assert-True -Condition ($optionalIds.Count -eq 0) -Message 'AI CLIs and Docker services must not be selected by default'

$plan = New-NoaulInstallPlan -Components @('codex', 'cc-switch') -IncludeRecommendedCore:$false
$planIds = @($plan | ForEach-Object { $_.Id })
Assert-Contains -Items $planIds -Expected 'nodejs' -Message 'Codex should pull in Node.js prerequisite'
Assert-Contains -Items $planIds -Expected 'codex' -Message 'Codex should be in selected plan'
Assert-Contains -Items $planIds -Expected 'cc-switch' -Message 'CC Switch should be in selected plan'
Assert-True -Condition ($planIds -notcontains 'claude-code') -Message 'Claude Code should not be installed when not selected'
Assert-True -Condition ($planIds -notcontains 'opencode') -Message 'OpenCode should not be installed when not selected'
Assert-True -Condition ($planIds -notcontains 'kiro') -Message 'Kiro should not be installed when not selected'

$commaPlan = New-NoaulInstallPlan -Components @('codex,cc-switch') -IncludeRecommendedCore:$false
$commaPlanIds = @($commaPlan | ForEach-Object { $_.Id })
Assert-Contains -Items $commaPlanIds -Expected 'codex' -Message 'Comma-separated CLI input should select Codex'
Assert-Contains -Items $commaPlanIds -Expected 'cc-switch' -Message 'Comma-separated CLI input should select CC Switch'

Invoke-NoaulInstallPlan -Plan $plan -DryRun -InstallRoot (Join-Path ([System.IO.Path]::GetTempPath()) 'noaul-dry-run-test') | Out-Null

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('noaul-tests-' + [guid]::NewGuid().ToString('N'))
try {
    New-NoaulDockerServiceFiles `
        -Services @('cpa', 'cpa-usage-keeper', 'sub2api') `
        -InstallRoot $tempRoot `
        -Secrets @{
            CpaManagementKey = 'test-management-key'
            KeeperLoginPassword = 'test-login-password'
            Sub2ApiPostgresPassword = 'test-postgres-password'
            Sub2ApiJwtSecret = 'test-jwt-secret'
            Sub2ApiTotpKey = 'test-totp-key'
        } | Out-Null

    $cpaCompose = Get-Content -LiteralPath (Join-Path $tempRoot 'services/cpa-stack/docker-compose.yml') -Raw
    $cpaEnv = Get-Content -LiteralPath (Join-Path $tempRoot 'services/cpa-stack/.env') -Raw
    $sub2apiCompose = Get-Content -LiteralPath (Join-Path $tempRoot 'services/sub2api/docker-compose.yml') -Raw
    $sub2apiEnv = Get-Content -LiteralPath (Join-Path $tempRoot 'services/sub2api/.env') -Raw

    Assert-True -Condition ($cpaCompose -match 'eceasy/cli-proxy-api:latest') -Message 'CPA compose should use CLIProxyAPI image'
    Assert-True -Condition ($cpaCompose -match 'ghcr.io/willxup/cpa-usage-keeper:latest') -Message 'CPA compose should include CPA Usage Keeper when selected'
    Assert-True -Condition ($cpaCompose -match 'CPA_MANAGEMENT_KEY') -Message 'CPA compose should read the management key from .env'
    Assert-True -Condition ($cpaEnv -match 'test-management-key') -Message 'CPA management key should be written into generated env file'
    Assert-True -Condition ($sub2apiCompose -match 'weishaw/sub2api:latest') -Message 'Sub2API compose should use Sub2API image'
    Assert-True -Condition ($sub2apiCompose -match 'postgres:18-alpine') -Message 'Sub2API compose should include PostgreSQL'
    Assert-True -Condition ($sub2apiCompose -match 'redis:8-alpine') -Message 'Sub2API compose should include Redis'
    Assert-True -Condition ($sub2apiEnv -match 'test-postgres-password') -Message 'Sub2API generated env should contain supplied database secret'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host 'Noaul tests passed.'
