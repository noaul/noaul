#!/usr/bin/env bash
set -euo pipefail

CC_SWITCH_CLI_INSTALL_URL="https://github.com/saladday/cc-switch-cli/releases/latest/download/install.sh"
UV_INSTALL_URL="https://astral.sh/uv/install.sh"

DEFAULT_COMPONENTS=(
  git
  curl
  ripgrep
  nodejs
  npm
  python
  uv
)

ALL_COMPONENTS=(
  git
  curl
  ripgrep
  fd
  jq
  gh
  git-lfs
  nodejs
  npm
  pnpm
  python
  uv
  pipx
  ruff
  codex
  claude-code
  opencode
  cc-switch
)

PACKAGE_INDEX_UPDATED=0
declare -A INSTALLED_COMPONENTS=()

log() {
  printf '[noaul] %s\n' "$*"
}

die() {
  printf '[noaul] error: %s\n' "$*" >&2
  exit 1
}

is_dry_run() {
  [[ "${NOAUL_DRY_RUN:-}" == "1" ]]
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

need_command() {
  has_command "$1" || die "$1 was not found. Install $1 first, then rerun Noaul."
}

run_cmd() {
  if is_dry_run; then
    log "dry-run: $*"
    return
  fi

  "$@"
}

run_root() {
  if is_dry_run; then
    log "dry-run: $*"
    return
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return
  fi

  need_command sudo
  sudo "$@"
}

detect_package_manager() {
  for pm in apt-get dnf yum pacman zypper apk brew; do
    if has_command "$pm"; then
      printf '%s\n' "$pm"
      return
    fi
  done

  if is_dry_run; then
    printf 'unknown\n'
    return
  fi

  die "no supported package manager found. Supported: apt, dnf, yum, pacman, zypper, apk, brew."
}

install_os_packages() {
  if [[ "$#" -eq 0 ]]; then
    return
  fi

  local pm
  pm="$(detect_package_manager)"

  case "$pm" in
    apt-get)
      if [[ "$PACKAGE_INDEX_UPDATED" -eq 0 ]]; then
        run_root apt-get update
        PACKAGE_INDEX_UPDATED=1
      fi
      run_root apt-get install -y "$@"
      ;;
    dnf)
      run_root dnf install -y "$@"
      ;;
    yum)
      run_root yum install -y "$@"
      ;;
    pacman)
      run_root pacman -Sy --needed --noconfirm "$@"
      ;;
    zypper)
      run_root zypper --non-interactive install "$@"
      ;;
    apk)
      run_root apk add --no-cache "$@"
      ;;
    brew)
      run_cmd brew install "$@"
      ;;
    unknown)
      log "dry-run: install packages: $*"
      ;;
  esac
}

component_available() {
  case "$1" in
    fd)
      has_command fd || has_command fdfind
      ;;
    nodejs)
      has_command node
      ;;
    python)
      has_command python3 || has_command python
      ;;
    npm)
      has_command npm
      ;;
    git-lfs)
      has_command git-lfs
      ;;
    claude-code)
      has_command claude
      ;;
    *)
      has_command "$1"
      ;;
  esac
}

install_package_component() {
  local id="$1"
  if component_available "$id"; then
    log "skip: ${id} is already available"
    return
  fi

  local pm
  pm="$(detect_package_manager)"
  local packages=()

  case "$id" in
    git)
      packages=(git)
      ;;
    curl)
      packages=(curl)
      ;;
    ripgrep)
      packages=(ripgrep)
      ;;
    fd)
      case "$pm" in
        apt-get|dnf|yum) packages=(fd-find) ;;
        *) packages=(fd) ;;
      esac
      ;;
    jq)
      packages=(jq)
      ;;
    gh)
      packages=(gh)
      ;;
    git-lfs)
      packages=(git-lfs)
      ;;
    nodejs)
      case "$pm" in
        brew) packages=(node) ;;
        *) packages=(nodejs npm) ;;
      esac
      ;;
    python)
      case "$pm" in
        apt-get) packages=(python3 python3-pip python3-venv) ;;
        pacman) packages=(python python-pip) ;;
        apk) packages=(python3 py3-pip) ;;
        brew) packages=(python) ;;
        *) packages=(python3 python3-pip) ;;
      esac
      ;;
    pipx)
      case "$pm" in
        pacman) packages=(python-pipx) ;;
        zypper) packages=(python3-pipx) ;;
        apk) packages=(pipx) ;;
        *) packages=(pipx) ;;
      esac
      ;;
    *)
      die "unsupported package component: ${id}"
      ;;
  esac

  install_os_packages "${packages[@]}"

  if [[ "$id" == "git-lfs" ]] && component_available git-lfs; then
    run_cmd git lfs install --skip-repo
  fi
  if [[ "$id" == "pipx" ]] && component_available pipx; then
    run_cmd pipx ensurepath
  fi
}

install_npm_runtime() {
  install_component nodejs

  if component_available npm; then
    log "skip: npm is already available"
    return
  fi

  install_os_packages npm
  if is_dry_run; then
    log "dry-run: verify npm command"
    return
  fi
  need_command npm
}

install_npm_package() {
  local id="$1"
  local package="$2"
  local command_name="$3"

  if has_command "$command_name"; then
    log "skip: ${id} is already available"
    return
  fi

  install_npm_runtime
  run_cmd npm install -g "${package}@latest"

  if [[ "$id" == "codex" ]]; then
    set_codex_reasoning_effort
  fi
}

set_codex_reasoning_effort() {
  local config_dir="${HOME}/.codex"
  local config_file="${config_dir}/config.toml"

  if is_dry_run; then
    log "dry-run: set Codex model_reasoning_effort = \"xhigh\" in ${config_file}"
    return
  fi

  mkdir -p "$config_dir"
  if [[ -f "$config_file" ]] && grep -q '^model_reasoning_effort' "$config_file"; then
    sed -i.bak 's/^model_reasoning_effort.*/model_reasoning_effort = "xhigh"/' "$config_file"
  else
    printf '\nmodel_reasoning_effort = "xhigh"\n' >> "$config_file"
  fi
}

install_uv() {
  if component_available uv; then
    log "skip: uv is already available"
    return
  fi

  install_component curl

  if is_dry_run; then
    log "dry-run: curl -LsSf ${UV_INSTALL_URL} | sh"
    return
  fi

  curl -LsSf "$UV_INSTALL_URL" | sh
}

install_ruff() {
  if component_available ruff; then
    log "skip: ruff is already available"
    return
  fi

  if is_dry_run; then
    log "dry-run: uv tool install ruff"
    return
  fi

  install_component uv
  if has_command uv; then
    run_cmd uv tool install ruff
    return
  fi

  install_component pipx
  run_cmd pipx install ruff
}

install_cc_switch() {
  install_component curl

  local force="${CC_SWITCH_FORCE:-1}"
  if is_dry_run; then
    log "dry-run: install cc-switch from ${CC_SWITCH_CLI_INSTALL_URL} with CC_SWITCH_FORCE=${force}"
    return
  fi

  log "installing cc-switch from saladday/cc-switch-cli"
  curl -fsSL "${CC_SWITCH_CLI_INSTALL_URL}" | CC_SWITCH_FORCE="${force}" bash
}

install_component_list() {
  local component
  for component in "$@"; do
    install_component "$component"
  done
}

install_component() {
  local component="$1"
  case "$component" in
    default)
      install_component_list "${DEFAULT_COMPONENTS[@]}"
      return
      ;;
    all)
      install_component_list "${ALL_COMPONENTS[@]}"
      return
      ;;
    help|--help|-h)
      print_help
      return
      ;;
  esac

  if [[ -n "${INSTALLED_COMPONENTS[$component]:-}" ]]; then
    return
  fi
  INSTALLED_COMPONENTS[$component]=1

  case "$component" in
    git|curl|ripgrep|fd|jq|gh|git-lfs|nodejs|python|pipx)
      install_package_component "$component"
      ;;
    npm)
      install_npm_runtime
      ;;
    pnpm)
      install_npm_package pnpm pnpm pnpm
      ;;
    uv)
      install_uv
      ;;
    ruff)
      install_ruff
      ;;
    codex)
      install_npm_package codex @openai/codex codex
      ;;
    claude-code)
      install_npm_package claude-code @anthropic-ai/claude-code claude
      ;;
    opencode)
      install_npm_package opencode opencode-ai opencode
      ;;
    cc-switch)
      install_cc_switch
      ;;
    winget|scoop|kiro|powershell|vscode|docker-desktop|visual-build-tools|7zip|cpa|cpa-usage-keeper|sub2api)
      die "${component} is not supported by the Linux shell installer"
      ;;
    *)
      die "unsupported Linux component: ${component}"
      ;;
  esac
}

print_help() {
  cat <<'EOF'
Usage:
  curl -fsSL https://noaul.uov.me/linux | bash
  curl -fsSL https://noaul.uov.me/linux | bash -s -- codex cc-switch
  curl -fsSL https://noaul.uov.me/linux | bash -s -- all

Environment:
  NOAUL_INSTALL="codex,cc-switch"  Select components without CLI args
  NOAUL_DRY_RUN=1                  Print commands without installing
  CC_SWITCH_FORCE=1                Passed to cc-switch-cli installer

Defaults:
  git curl ripgrep nodejs npm python uv

Supported:
  git curl ripgrep fd jq gh git-lfs nodejs npm pnpm python uv pipx ruff codex claude-code opencode cc-switch
EOF
}

main() {
  local requested="${NOAUL_INSTALL:-}"
  if [[ "$#" -gt 0 ]]; then
    requested="$*"
  fi
  if [[ -z "${requested// }" ]]; then
    requested="default"
  fi

  requested="${requested//,/ }"
  local component
  for component in ${requested}; do
    install_component "$component"
  done
}

main "$@"
