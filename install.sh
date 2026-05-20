#!/usr/bin/env bash
set -euo pipefail

CC_SWITCH_CLI_INSTALL_URL="https://github.com/saladday/cc-switch-cli/releases/latest/download/install.sh"

log() {
  printf '[noaul] %s\n' "$*"
}

die() {
  printf '[noaul] error: %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 was not found. Install $1 first, then rerun Noaul."
}

install_cc_switch() {
  need_command curl

  local force="${CC_SWITCH_FORCE:-1}"
  if [[ "${NOAUL_DRY_RUN:-}" == "1" ]]; then
    log "dry-run: install cc-switch from ${CC_SWITCH_CLI_INSTALL_URL} with CC_SWITCH_FORCE=${force}"
    return
  fi

  log "installing cc-switch from saladday/cc-switch-cli"
  curl -fsSL "${CC_SWITCH_CLI_INSTALL_URL}" | CC_SWITCH_FORCE="${force}" bash
}

main() {
  local requested="${NOAUL_INSTALL:-}"
  if [[ "$#" -gt 0 ]]; then
    requested="$*"
  fi
  if [[ -z "${requested// }" ]]; then
    requested="cc-switch"
  fi

  requested="${requested//,/ }"
  for component in ${requested}; do
    case "${component}" in
      cc-switch)
        install_cc_switch
        ;;
      help|--help|-h)
        printf 'Usage: curl -fsSL https://noaul.uov.me/linux | bash\n'
        printf '       curl -fsSL https://noaul.uov.me/linux | bash -s -- cc-switch\n'
        printf 'Environment: NOAUL_INSTALL=cc-switch NOAUL_DRY_RUN=1 CC_SWITCH_FORCE=1\n'
        ;;
      *)
        die "unsupported Linux component: ${component}. Currently supported: cc-switch"
        ;;
    esac
  done
}

main "$@"
