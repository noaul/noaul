$ErrorActionPreference = 'Stop'

Describe 'Linux one-click installer' {
    BeforeAll {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $linuxInstaller = Join-Path $repoRoot 'install.sh'
        $script:Content = Get-Content -LiteralPath $linuxInstaller -Raw
    }

    It 'Defaults to the Linux recommended set instead of only cc-switch' {
        $script:Content | Should -Match 'requested="default"'
        $script:Content | Should -Match 'DEFAULT_COMPONENTS'
    }

    It 'Includes npm-based AI CLI tools on Linux' {
        $script:Content | Should -Match '@openai/codex'
        $script:Content | Should -Match '@anthropic-ai/claude-code'
        $script:Content | Should -Match 'opencode-ai'
    }

    It 'Uses cc-switch-cli as the Linux-specific cc-switch installer' {
        $script:Content | Should -Match 'saladday/cc-switch-cli/releases/latest/download/install.sh'
        $script:Content | Should -Match 'CC_SWITCH_FORCE'
    }
}
