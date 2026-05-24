Set-StrictMode -Version Latest

$script:ModuleRoot = $PSScriptRoot
Import-Module (Join-Path $script:ModuleRoot 'Noaul.Catalog.psm1') -Force
Import-Module (Join-Path $script:ModuleRoot 'Noaul.Installer.psm1') -Force

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

Export-ModuleMember -Function `
    ConvertTo-YamlScalar, `
    New-NoaulCpaStackFiles, `
    New-NoaulSub2ApiFiles, `
    New-NoaulDockerServiceFiles, `
    Start-NoaulDockerServices, `
    Update-NoaulDockerServices
