#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

pass_count=0
fail_count=0

run_test() {
  local name="$1"
  shift

  if "$@"; then
    printf 'PASS %s\n' "$name"
    pass_count=$((pass_count + 1))
  else
    printf 'FAIL %s\n' "$name" >&2
    fail_count=$((fail_count + 1))
  fi
}

run_setup_with_stubs() {
  local name="$1"
  shift
  local trace="$TEMP_ROOT/$name.trace"
  local output="$TEMP_ROOT/$name.out"
  local home="$TEMP_ROOT/$name.home"
  mkdir -p "$home"

  TRACE_FILE="$trace" ROOT_DIR="$ROOT_DIR" HOME="$home" bash -c '
    sudo() {
      printf "sudo %s\n" "$*" >>"$TRACE_FILE"
      return 0
    }
    brew() {
      printf "%s\n" /tmp/fake-homebrew
    }
    git() {
      printf "git %s\n" "$*" >>"$TRACE_FILE"
      if [[ "$*" == *"remote get-url origin"* ]]; then
        printf "%s\n" https://github.com/Homebrew/brew
      fi
      return 0
    }
    source "$ROOT_DIR/setup.sh" "$@"
  ' mac-setup-test "$@" >"$output" 2>&1
}

test_help_has_no_side_effects() {
  run_setup_with_stubs help --help || return 1
  [[ ! -s "$TEMP_ROOT/help.trace" ]] || return 1
  grep -q '^用法:' "$TEMP_ROOT/help.out"
}

test_dry_run_is_scoped_and_side_effect_free() {
  run_setup_with_stubs dry-run --dry-run --modules agents || return 1
  [[ ! -s "$TEMP_ROOT/dry-run.trace" ]] || return 1
  grep -q '/modules/agents.sh' "$TEMP_ROOT/dry-run.out" || return 1
  ! grep -q '/platforms/' "$TEMP_ROOT/dry-run.out"
}

test_unknown_argument_fails_before_side_effects() {
  if run_setup_with_stubs unknown --dry-run --unknown; then
    return 1
  fi
  [[ ! -s "$TEMP_ROOT/unknown.trace" ]] || return 1
  grep -q '未知参数' "$TEMP_ROOT/unknown.out"
}

test_unknown_module_fails_before_side_effects() {
  if run_setup_with_stubs unknown-module --dry-run --modules does-not-exist; then
    return 1
  fi
  [[ ! -s "$TEMP_ROOT/unknown-module.trace" ]] || return 1
  grep -q '未知模块' "$TEMP_ROOT/unknown-module.out"
}

test_missing_modules_value_is_reported() {
  if run_setup_with_stubs missing-modules --dry-run --modules; then
    return 1
  fi
  [[ ! -s "$TEMP_ROOT/missing-modules.trace" ]] || return 1
  grep -q -- '--modules 需要参数' "$TEMP_ROOT/missing-modules.out"
}

test_no_root_skips_sudo() {
  run_setup_with_stubs no-root --no-root --modules sync || return 1
  ! grep -q '^sudo ' "$TEMP_ROOT/no-root.trace"
}

test_scoped_user_module_skips_sudo() {
  run_setup_with_stubs scoped-user-module --modules sync || return 1
  ! grep -q '^sudo ' "$TEMP_ROOT/scoped-user-module.trace"
}

test_linux_package_install_uses_sudo_for_non_root() {
  [[ $EUID -ne 0 ]] || return 0
  local output
  output="$TEMP_ROOT/linux-package.out"

  ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/package.sh"
    sudo() {
      if [[ "${1:-}" == "-n" ]]; then
        return 0
      fi
      printf "sudo-call:%s\n" "$*"
    }
    apt() {
      printf "direct-apt-call:%s\n" "$*"
    }
    _pkg_install_linux demo-package
  ' >"$output" 2>&1 || return 1

  grep -q '^sudo-call:apt install -y demo-package$' "$output" || return 1
  ! grep -q '^direct-apt-call:' "$output"
}

test_no_root_package_install_is_a_clean_skip() {
  local output="$TEMP_ROOT/no-root-package.out"

  ROOT_DIR="$ROOT_DIR" MAC_SETUP_NO_ROOT=1 bash -c '
    source "$ROOT_DIR/lib/package.sh"
    log() { :; }
    detect_platform() { printf "%s\n" ubuntu; }
    pkg_exists() { return 1; }
    can_sudo() {
      printf "%s\n" unexpected-sudo-check
      return 1
    }
    apt() {
      printf "%s\n" unexpected-apt-call
      return 1
    }
    pkg_install demo-package
  ' >"$output" 2>&1 || return 1

  [[ ! -s "$output" ]]
}

test_opencode_module_has_no_implicit_sudo() {
  local trace="$TEMP_ROOT/opencode.trace"
  local result="$TEMP_ROOT/opencode-root.out"
  local home="$TEMP_ROOT/opencode.home"
  mkdir -p "$home"

  TRACE_FILE="$trace" RESULT_FILE="$result" ROOT_DIR="$ROOT_DIR" HOME="$home" bash -c '
    MODULES=()
    SCRIPT_ROOT="$ROOT_DIR"
    opencode() {
      [[ "${1:-}" == "--version" ]] && printf "%s\n" test-version
      return 0
    }
    brew() { return 0; }
    sudo() {
      printf "sudo %s\n" "$*" >>"$TRACE_FILE"
      return 0
    }
    sleep() { return 0; }
    kill() { return 1; }
    source "$ROOT_DIR/modules/opencode.sh"
    printf "%s\n" "$SCRIPT_ROOT" >"$RESULT_FILE"
  ' >/dev/null 2>&1 || return 1

  [[ ! -s "$trace" ]] || return 1
  [[ "$(<"$result")" == "$ROOT_DIR" ]]
}

test_tool_command_mapping() {
  local output
  output="$(ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/package.sh"
    tool_command_name git-delta
    tool_command_name the_silver_searcher
    tool_command_name sevenzip
  ' 2>/dev/null)" || return 1

  [[ "$output" == $'delta\nag\n7zz' ]]
}

test_node_module_installs_pinned_bun_runtime() {
  local trace="$TEMP_ROOT/node-runtime.trace"
  local fake_mise="$TEMP_ROOT/fake-mise"
  local home="$TEMP_ROOT/node-runtime.home"
  mkdir -p "$home"
  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$MISE_TRACE"' \
    'exit 0' >"$fake_mise"
  chmod +x "$fake_mise"

  ROOT_DIR="$ROOT_DIR" HOME="$home" FAKE_MISE="$fake_mise" MISE_TRACE="$trace" bash -c '
    log() { :; }
    install_mise() { :; }
    resolve_mise_executable() { printf "%s\n" "$FAKE_MISE"; }
    npm() {
      [[ "${1:-}" == "list" ]] && return 0
      return 0
    }
    source "$ROOT_DIR/modules/nodejs.sh"
  ' >/dev/null 2>&1 || return 1

  grep -q '^use -g node@lts$' "$trace" || return 1
  grep -q '^use -g bun@1.3.7$' "$trace"
}

test_binary_downloads_use_private_temporary_directories() {
  ! grep -Eq 'tmp_dir="/tmp/mise-install"|"/tmp/(fzf|yazi)\.' \
    "$ROOT_DIR/lib/utils.sh" "$ROOT_DIR/modules/cli-tools.sh" || return 1
  ! grep -q 'ghproxy.com' "$ROOT_DIR/modules/cli-tools.sh"
}

test_platform_script_directories_include_linux_base() {
  local output
  output="$(ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/platform.sh"
    detect_platform() { printf "%s\n" ubuntu; }
    platform_script_dirs /repo/platforms
  ' 2>/dev/null)" || return 1

  [[ "$output" == $'/repo/platforms/linux\n/repo/platforms/ubuntu' ]]
}

test_shell_config_guards_optional_integrations() {
  ! grep -q 'opencode && /' "$ROOT_DIR/config/.zshrc" \
    "$ROOT_DIR/modules/opencode.sh" || return 1
  ! grep -q '^\. "$HOME/.local/bin/env"$' "$ROOT_DIR/config/.zshrc" || return 1
  ! grep -q '^source "$HOME/.openclaw/completions/openclaw.zsh"$' \
    "$ROOT_DIR/config/.zshrc" || return 1
  [[ "$(grep -c '^export BUN_INSTALL=' "$ROOT_DIR/config/.zshrc")" == "1" ]]
}

run_test help-has-no-side-effects test_help_has_no_side_effects
run_test dry-run-is-scoped-and-side-effect-free test_dry_run_is_scoped_and_side_effect_free
run_test unknown-argument-fails-before-side-effects test_unknown_argument_fails_before_side_effects
run_test unknown-module-fails-before-side-effects test_unknown_module_fails_before_side_effects
run_test missing-modules-value-is-reported test_missing_modules_value_is_reported
run_test no-root-skips-sudo test_no_root_skips_sudo
run_test scoped-user-module-skips-sudo test_scoped_user_module_skips_sudo
run_test linux-package-install-uses-sudo test_linux_package_install_uses_sudo_for_non_root
run_test no-root-package-install-is-clean-skip test_no_root_package_install_is_a_clean_skip
run_test opencode-module-has-no-implicit-sudo test_opencode_module_has_no_implicit_sudo
run_test tool-command-mapping test_tool_command_mapping
run_test node-module-installs-pinned-bun-runtime test_node_module_installs_pinned_bun_runtime
run_test binary-downloads-use-private-temporary-directories \
  test_binary_downloads_use_private_temporary_directories
run_test platform-script-directories-include-linux-base \
  test_platform_script_directories_include_linux_base
run_test shell-config-guards-optional-integrations \
  test_shell_config_guards_optional_integrations

if ((fail_count > 0)); then
  printf 'FAIL setup tests (%d passed, %d failed)\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS setup tests (%d cases)\n' "$pass_count"
