Set-StrictMode -Version Latest

function Read-NoaulYesNo {
    param(
        [Parameter(Mandatory)][string] $Prompt,
        [bool] $Default = $false
    )

    $suffix = '[Y/N]'
    while ($true) {
        $answer = Read-Host "$Prompt $suffix"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default
        }

        switch -Regex ($answer.Trim()) {
            '^(y|yes)$' { return $true }
            '^(n|no)$' { return $false }
            default { Write-Host 'Please answer Y or N.' }
        }
    }
}

function Read-NoaulInstallMode {
    while ($true) {
        $answer = Read-Host 'Choose action: install new tools or update installed tools? [I/U]'
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return 'update'
        }

        switch -Regex ($answer.Trim()) {
            '^(i|install)$' { return 'install' }
            '^(u|update)$' { return 'update' }
            default { Write-Host 'Please answer INSTALL or UPDATE.' }
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
        if (-not (Read-NoaulYesNo -Prompt 'Proceed with this plan?' -Default:$true)) {
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
    Read-NoaulYesNo, `
    Read-NoaulInstallMode, `
    Select-NoaulComponentsInteractive, `
    Show-NoaulPlan, `
    Start-Noaul
