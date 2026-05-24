[CmdletBinding()]
param(
    [string] $OutputPath = (Join-Path $PSScriptRoot 'dist/Noaul.psm1')
)

$ErrorActionPreference = 'Stop'
$srcDir = Join-Path $PSScriptRoot 'src'

$moduleOrder = @(
    'Noaul.Catalog.psm1'
    'Noaul.Installer.psm1'
    'Noaul.Docker.psm1'
    'Noaul.UI.psm1'
)

$parts = New-Object System.Collections.Generic.List[string]
$parts.Add('Set-StrictMode -Version Latest')
$parts.Add('')

foreach ($moduleName in $moduleOrder) {
    $modulePath = Join-Path $srcDir $moduleName
    $content = Get-Content -LiteralPath $modulePath -Raw

    # Strip Set-StrictMode, Import-Module, Export-ModuleMember blocks, and $script:ModuleRoot
    $lines = $content -split '\r?\n'
    $filtered = New-Object System.Collections.Generic.List[string]
    $skipBlock = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*Set-StrictMode') { continue }
        if ($line -match '^\s*Import-Module') { continue }
        if ($line -match '^\s*\$script:ModuleRoot') { continue }
        if ($line -match '^\s*Export-ModuleMember') {
            $skipBlock = $true
            # Check if line ends with backtick continuation
            if ($line -match '`\s*$') { continue }
            else { $skipBlock = $false; continue }
        }
        if ($skipBlock) {
            if ($line -match '`\s*$') { continue }
            else { $skipBlock = $false; continue }
        }
        $filtered.Add($line)
    }

    $parts.Add("# --- $moduleName ---")
    $parts.Add(($filtered.ToArray() -join "`n").Trim())
    $parts.Add('')
}

# Add root-level export
$rootModule = Get-Content -LiteralPath (Join-Path $srcDir 'Noaul.psm1') -Raw
$rootLines = $rootModule -split '\r?\n'
$exportLines = New-Object System.Collections.Generic.List[string]
$inExport = $false
foreach ($line in $rootLines) {
    if ($line -match '^\s*Export-ModuleMember') { $inExport = $true }
    if ($inExport) {
        $exportLines.Add($line)
        if ($line -notmatch '`\s*$') { break }
    }
}
$parts.Add(($exportLines.ToArray() -join "`n"))

$bundle = $parts -join "`n"

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $bundle -Encoding utf8
Write-Host "Bundled module written to: $OutputPath"
