#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/bin/mac-setup"
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

write_fake_command() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$path"
  chmod +x "$path"
}

write_fake_nvim() {
  local path="$1"
  local version="$2"
  local trace="${3:-}"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' \
    'if [[ "${1:-}" == "--version" ]]; then' \
    "  printf '%s\\n' 'NVIM v$version'" \
    '  exit 0' \
    'fi' \
    "printf '%s\\n' \"\$*\" >>'$trace'" \
    '[[ "${MAC_SETUP_NVIM_VERIFY:-}" == "1" ]] || exit 1' \
    '[[ "$*" == *"--headless"* ]] || exit 1' \
    '[[ "$*" != *"--clean"* ]]' >"$path"
  chmod +x "$path"
}

json_assert() {
  local path="$1"
  local expression="$2"
  python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle)
if not eval(
    sys.argv[2],
    {"__builtins__": {}},
    {"value": value, "set": set, "len": len},
):
    raise SystemExit(1)
' "$path" "$expression"
}

test_manifest_pins_official_neovim_release() {
  local manifest="$ROOT_DIR/config/bootstrap/neovim.tsv"
  [[ -f "$manifest" ]] || return 1
  ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/bootstrap-manifest.sh"
    validate_neovim_bootstrap_manifest "$ROOT_DIR"
    [[ "$(neovim_bootstrap_version "$ROOT_DIR")" == "0.12.4" ]]
  ' >/dev/null 2>&1 || return 1

  python3 - "$manifest" <<'PY'
import pathlib
import sys

records = {}
for line in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if not line or line.startswith("#"):
        continue
    version, os_name, arch, filename, sha256 = line.split("\t")
    records[(os_name, arch)] = (version, filename, sha256)

expected = {
    ("linux", "arm64"): (
        "0.12.4",
        "nvim-linux-arm64.tar.gz",
        "ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f",
    ),
    ("linux", "x64"): (
        "0.12.4",
        "nvim-linux-x86_64.tar.gz",
        "012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628",
    ),
    ("macos", "arm64"): (
        "0.12.4",
        "nvim-macos-arm64.tar.gz",
        "51ab83afa66d663627c2ab1be43209b0f4e81360d4598b53efaa4d8195f24c89",
    ),
    ("macos", "x64"): (
        "0.12.4",
        "nvim-macos-x86_64.tar.gz",
        "03fe16f8dd9f1e9eaf52d5e294913a39917b9e2faea30d7fb0fb385fbd36fe59",
    ),
}
if records != expected:
    raise SystemExit(1)
PY
}

test_manifest_pins_supported_tree_sitter_cli() {
  local manifest="$ROOT_DIR/config/bootstrap/tree-sitter.tsv"
  [[ -f "$manifest" ]] || return 1
  ROOT_DIR="$ROOT_DIR" bash -c '
    source "$ROOT_DIR/lib/bootstrap-manifest.sh"
    validate_tree_sitter_bootstrap_manifest "$ROOT_DIR"
    [[ "$(tree_sitter_bootstrap_version "$ROOT_DIR")" == "0.26.11" ]]
  ' >/dev/null 2>&1 || return 1

  python3 - "$manifest" <<'PY'
import pathlib
import sys

records = {}
for line in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    if not line or line.startswith("#"):
        continue
    version, os_name, arch, method, artifact, sha256, build_runtime = line.split("\t")
    records[(os_name, arch)] = (
        version,
        method,
        artifact,
        sha256,
        build_runtime,
    )

expected = {
    ("linux", "arm64"): (
        "0.26.11",
        "crates-io",
        "tree-sitter-cli-0.26.11.crate",
        "a6f16e9ff5d7f9b59635332fde46be6a36efdf8bd811f96b5f6ad1678367d6a2",
        "rust@1.88.0",
    ),
    ("linux", "x64"): (
        "0.26.11",
        "crates-io",
        "tree-sitter-cli-0.26.11.crate",
        "a6f16e9ff5d7f9b59635332fde46be6a36efdf8bd811f96b5f6ad1678367d6a2",
        "rust@1.88.0",
    ),
    ("macos", "arm64"): (
        "0.26.11",
        "github-release",
        "tree-sitter-cli-macos-arm64.zip",
        "050f41d60a054b608ea392ba14722bba9457bdc0ab11a5706c77f034dafc68ac",
        "-",
    ),
    ("macos", "x64"): (
        "0.26.11",
        "github-release",
        "tree-sitter-cli-macos-x64.zip",
        "e3c2cdec71bbc60344b25df3dad5da378a174f2292af953ff0d641e06aaee099",
        "-",
    ),
}
if records != expected:
    raise SystemExit(1)
PY
}

test_linux_tree_sitter_uses_locked_cargo_source_build() {
  local home="$TEMP_ROOT/tree-sitter-install.home"
  local fixture_root="$TEMP_ROOT/tree-sitter-install.fixture"
  local fixture="$TEMP_ROOT/tree-sitter-cli-0.26.11.crate"
  local fake_mise="$TEMP_ROOT/tree-sitter-install.mise"
  local trace="$TEMP_ROOT/tree-sitter-install.trace"
  local expected_sha256
  mkdir -p "$home" "$fixture_root/tree-sitter-cli-0.26.11"
  printf '%s\n' '[package]' 'name = "tree-sitter-cli"' 'version = "0.26.11"' \
    >"$fixture_root/tree-sitter-cli-0.26.11/Cargo.toml"
  printf '%s\n' '# locked fixture' >"$fixture_root/tree-sitter-cli-0.26.11/Cargo.lock"
  tar -czf "$fixture" -C "$fixture_root" tree-sitter-cli-0.26.11 || return 1
  expected_sha256="$(ROOT_DIR="$ROOT_DIR" FIXTURE="$fixture" bash -c '
    source "$ROOT_DIR/lib/utils.sh"
    file_sha256 "$FIXTURE"
  ')" || return 1

  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >>"$MISE_TRACE"' \
    'if [[ "${1:-}" == "install" && "${2:-}" == "rust@1.88.0" ]]; then' \
    '  exit 0' \
    'fi' \
    'if [[ "${1:-}" == "exec" && "${2:-}" == "rust@1.88.0" ]]; then' \
    '  shift 3' \
    '  install_root=""' \
    '  while [[ $# -gt 0 ]]; do' \
    '    if [[ "$1" == "--root" ]]; then install_root="$2"; shift 2; else shift; fi' \
    '  done' \
    '  mkdir -p "$install_root/bin"' \
    '  printf "%s\n" "#!/usr/bin/env bash" "printf \"%s\\n\" \"tree-sitter 0.26.11\"" >"$install_root/bin/tree-sitter"' \
    '  chmod +x "$install_root/bin/tree-sitter"' \
    '  exit 0' \
    'fi' \
    'exit 1' >"$fake_mise"
  chmod +x "$fake_mise"

  ROOT_DIR="$ROOT_DIR" HOME="$home" FIXTURE="$fixture" \
    EXPECTED_SHA256="$expected_sha256" FAKE_MISE="$fake_mise" MISE_TRACE="$trace" \
    bash -c '
      source "$ROOT_DIR/lib/utils.sh"
      uname() {
        [[ "${1:-}" == "-m" ]] && printf "%s\n" x86_64 || printf "%s\n" Linux
      }
      tree_sitter_bootstrap_record() {
        printf "%s|%s|%s|%s|%s\n" 0.26.11 crates-io \
          tree-sitter-cli-0.26.11.crate "$EXPECTED_SHA256" rust@1.88.0
      }
      install_mise() { :; }
      resolve_mise_executable() { printf "%s\n" "$FAKE_MISE"; }
      curl() {
        local argument output_path="" take_next=false
        for argument in "$@"; do
          if [[ "$take_next" == true ]]; then
            output_path="$argument"
            take_next=false
            continue
          fi
          [[ "$argument" == "-o" ]] && take_next=true
        done
        cp "$FIXTURE" "$output_path"
      }
      install_tree_sitter_cli
    ' >/dev/null 2>&1 || return 1

  [[ -L "$home/.local/bin/tree-sitter" ]] || return 1
  [[ "$("$home/.local/bin/tree-sitter" --version)" == 'tree-sitter 0.26.11' ]] || return 1
  grep -Fxq 'install rust@1.88.0' "$trace" || return 1
  grep -Fq \
    'exec rust@1.88.0 -- cargo install --locked --no-default-features --path ' "$trace"
}

test_installer_replaces_old_neovim_with_pinned_runtime() {
  local home="$TEMP_ROOT/install.home"
  local fixture_root="$TEMP_ROOT/install.fixture"
  local fixture="$TEMP_ROOT/install.tar.gz"
  local expected_sha256
  mkdir -p "$home/.local/bin" "$fixture_root/nvim-linux-x86_64/bin"
  write_fake_nvim "$home/.local/bin/nvim" 0.10.4
  write_fake_nvim "$fixture_root/nvim-linux-x86_64/bin/nvim" 0.12.4
  tar -czf "$fixture" -C "$fixture_root" nvim-linux-x86_64 || return 1
  expected_sha256="$(ROOT_DIR="$ROOT_DIR" FIXTURE="$fixture" bash -c '
    source "$ROOT_DIR/lib/utils.sh"
    file_sha256 "$FIXTURE"
  ')" || return 1

  ROOT_DIR="$ROOT_DIR" HOME="$home" FIXTURE="$fixture" EXPECTED_SHA256="$expected_sha256" \
    bash -c '
      source "$ROOT_DIR/lib/utils.sh"
      uname() {
        [[ "${1:-}" == "-m" ]] && printf "%s\n" x86_64 || printf "%s\n" Linux
      }
      neovim_bootstrap_record() {
        printf "%s|%s|%s\n" 0.12.4 nvim-linux-x86_64.tar.gz "$EXPECTED_SHA256"
      }
      curl() {
        local argument output_path="" take_next=false
        for argument in "$@"; do
          if [[ "$take_next" == true ]]; then
            output_path="$argument"
            take_next=false
            continue
          fi
          [[ "$argument" == "-o" ]] && take_next=true
        done
        cp "$FIXTURE" "$output_path"
      }
      install_neovim_runtime
    ' >/dev/null 2>&1 || return 1

  [[ -L "$home/.local/bin/nvim" ]] || return 1
  [[ "$("$home/.local/bin/nvim" --version | head -n 1)" == 'NVIM v0.12.4' ]] || return 1
  [[ -x "$home/.local/share/neovim/versions/0.12.4/bin/nvim" ]]
}

test_checksum_failure_preserves_existing_neovim() {
  local home="$TEMP_ROOT/checksum.home"
  local fixture_root="$TEMP_ROOT/checksum.fixture"
  local fixture="$TEMP_ROOT/checksum.tar.gz"
  mkdir -p "$home/.local/bin" "$home/.local/share/neovim/versions/0.11.7/bin" \
    "$fixture_root/nvim-linux-x86_64/bin"
  write_fake_nvim "$home/.local/share/neovim/versions/0.11.7/bin/nvim" 0.11.7
  ln -s "$home/.local/share/neovim/versions/0.11.7/bin/nvim" "$home/.local/bin/nvim"
  write_fake_nvim "$fixture_root/nvim-linux-x86_64/bin/nvim" 0.12.4
  tar -czf "$fixture" -C "$fixture_root" nvim-linux-x86_64 || return 1

  ROOT_DIR="$ROOT_DIR" HOME="$home" FIXTURE="$fixture" bash -c '
    source "$ROOT_DIR/lib/utils.sh"
    declare -F install_neovim_runtime >/dev/null || exit 1
    uname() {
      [[ "${1:-}" == "-m" ]] && printf "%s\n" x86_64 || printf "%s\n" Linux
    }
    neovim_bootstrap_record() {
      printf "%s|%s|%s\n" 0.12.4 nvim-linux-x86_64.tar.gz \
        0000000000000000000000000000000000000000000000000000000000000000
    }
    curl() {
      local argument output_path="" take_next=false
      for argument in "$@"; do
        if [[ "$take_next" == true ]]; then
          output_path="$argument"
          take_next=false
          continue
        fi
        [[ "$argument" == "-o" ]] && take_next=true
      done
      cp "$FIXTURE" "$output_path"
    }
    ! install_neovim_runtime
  ' >/dev/null 2>&1 || return 1

  [[ "$("$home/.local/bin/nvim" --version | head -n 1)" == 'NVIM v0.11.7' ]]
}

test_vim_module_uses_pinned_runtime_installer() {
  local home="$TEMP_ROOT/module.home"
  local fake_bin="$TEMP_ROOT/module.bin"
  local trace="$TEMP_ROOT/module.trace"
  mkdir -p "$home" "$fake_bin"
  write_fake_command "$fake_bin/fd"

  ROOT_DIR="$ROOT_DIR" HOME="$home" TRACE="$trace" PATH="$fake_bin:/usr/bin:/bin" \
    MAC_SETUP_SKIP_NVIM_CONFIG=1 MAC_SETUP_SKIP_NVIM_PYTHON=1 bash -c '
      log() { :; }
      install_mise() { :; }
      install_neovim_runtime() { printf "%s\n" neovim-runtime >>"$TRACE"; }
      install_tree_sitter_cli() { printf "%s\n" tree-sitter-runtime >>"$TRACE"; }
      pkg_install() { printf "package:%s\n" "$1" >>"$TRACE"; }
      source "$ROOT_DIR/modules/vim.sh"
    ' >/dev/null 2>&1 || return 1

  grep -Fxq neovim-runtime "$trace" || return 1
  grep -Fxq tree-sitter-runtime "$trace" || return 1
  ! grep -Fxq package:neovim "$trace"
}

test_agent_plan_detects_neovim_version_drift() {
  local home="$TEMP_ROOT/plan.home"
  local state="$TEMP_ROOT/plan.state"
  local fake_bin="$TEMP_ROOT/plan.bin"
  local output="$TEMP_ROOT/plan.json"
  mkdir -p "$home/.config" "$fake_bin"
  ln -s "$ROOT_DIR/config/nvim" "$home/.config/nvim"
  write_fake_nvim "$fake_bin/nvim" 0.10.4
  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "tree-sitter 0.26.11"' >"$fake_bin/tree-sitter"
  chmod +x "$fake_bin/tree-sitter"
  write_fake_command "$fake_bin/rg"
  write_fake_command "$fake_bin/fd"
  write_fake_command "$fake_bin/cc"

  env OSTYPE=linux-gnu HOME="$home" XDG_STATE_HOME="$state" \
    PATH="$fake_bin:/usr/bin:/bin" "$CLI" plan vim --format json >"$output" || return 1
  json_assert "$output" 'value["status"] == "CHANGES_REQUIRED"' || return 1
  json_assert "$output" \
    'len([item for item in value["changes"] if item["type"] == "CONFIGURE_RUNTIME" and item["resource"] == "neovim@0.12.4"]) == 1' || return 1
  json_assert "$output" \
    'set(item["type"] for item in value["requiredApprovals"]) == {"network"}'
}

test_agent_plan_detects_missing_tree_sitter_cli() {
  local home="$TEMP_ROOT/tree-sitter-plan.home"
  local state="$TEMP_ROOT/tree-sitter-plan.state"
  local fake_bin="$TEMP_ROOT/tree-sitter-plan.bin"
  local output="$TEMP_ROOT/tree-sitter-plan.json"
  mkdir -p "$home/.config" "$home/.local/bin" "$fake_bin"
  ln -s "$ROOT_DIR/config/nvim" "$home/.config/nvim"
  write_fake_nvim "$home/.local/bin/nvim" 0.12.4
  write_fake_command "$fake_bin/rg"
  write_fake_command "$fake_bin/fd"
  write_fake_command "$fake_bin/cc"

  env OSTYPE=linux-gnu HOME="$home" XDG_STATE_HOME="$state" \
    PATH="$fake_bin:/usr/bin:/bin" "$CLI" plan vim --format json >"$output" || return 1
  json_assert "$output" \
    'len([item for item in value["changes"] if item["type"] == "CONFIGURE_RUNTIME" and item["resource"] == "tree-sitter@0.26.11"]) == 1' || return 1
  json_assert "$output" \
    'set(item["type"] for item in value["requiredApprovals"]) == {"network"}'
}

test_verify_requires_exact_version_and_loads_managed_config() {
  local home="$TEMP_ROOT/verify.home"
  local state="$TEMP_ROOT/verify.state"
  local fake_bin="$TEMP_ROOT/verify.bin"
  local output="$TEMP_ROOT/verify.json"
  local trace="$TEMP_ROOT/verify.trace"
  mkdir -p "$home/.config" "$home/.local/bin" "$fake_bin"
  ln -s "$ROOT_DIR/config/nvim" "$home/.config/nvim"
  write_fake_nvim "$home/.local/bin/nvim" 0.12.4 "$trace"
  printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "tree-sitter 0.26.11"' >"$home/.local/bin/tree-sitter"
  chmod +x "$home/.local/bin/tree-sitter"
  write_fake_command "$fake_bin/rg"
  write_fake_command "$fake_bin/fd"
  write_fake_command "$fake_bin/cc"

  env OSTYPE=linux-gnu HOME="$home" XDG_STATE_HOME="$state" \
    PATH="$fake_bin:/usr/bin:/bin" "$CLI" verify vim --format json >"$output" || return 1
  json_assert "$output" 'value["status"] == "COMPLIANT"' || return 1
  json_assert "$output" \
    'len([item for item in value["checks"] if item["id"] == "nvim-version" and item["status"] == "PASS"]) == 1' || return 1
  json_assert "$output" \
    'len([item for item in value["checks"] if item["id"] == "nvim-config-load" and item["status"] == "PASS"]) == 1' || return 1
  json_assert "$output" \
    'len([item for item in value["checks"] if item["id"] == "tree-sitter-version" and item["status"] == "PASS"]) == 1' || return 1
  grep -q -- '--headless' "$trace" || return 1
  ! grep -q -- '--clean' "$trace"
}

test_neovim_012_optional_packages_are_guarded() {
  local autocmd="$ROOT_DIR/config/nvim/lua/autocmd.lua"
  grep -Fq 'vim.fn.has("nvim-0.12")' "$autocmd" || return 1
  grep -Fq 'packadd nvim.difftool' "$autocmd" || return 1
  grep -Fq 'packadd nvim.undotree' "$autocmd"
}

run_test manifest-pins-official-neovim-release \
  test_manifest_pins_official_neovim_release
run_test manifest-pins-supported-tree-sitter-cli \
  test_manifest_pins_supported_tree_sitter_cli
run_test linux-tree-sitter-uses-locked-cargo-source-build \
  test_linux_tree_sitter_uses_locked_cargo_source_build
run_test installer-replaces-old-neovim-with-pinned-runtime \
  test_installer_replaces_old_neovim_with_pinned_runtime
run_test checksum-failure-preserves-existing-neovim \
  test_checksum_failure_preserves_existing_neovim
run_test vim-module-uses-pinned-runtime-installer \
  test_vim_module_uses_pinned_runtime_installer
run_test agent-plan-detects-neovim-version-drift \
  test_agent_plan_detects_neovim_version_drift
run_test agent-plan-detects-missing-tree-sitter-cli \
  test_agent_plan_detects_missing_tree_sitter_cli
run_test verify-requires-exact-version-and-loads-managed-config \
  test_verify_requires_exact_version_and_loads_managed_config
run_test neovim-012-optional-packages-are-guarded \
  test_neovim_012_optional_packages_are_guarded

if ((fail_count > 0)); then
  printf 'FAIL Neovim runtime tests (%d passed, %d failed)\n' \
    "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS Neovim runtime tests (%d cases)\n' "$pass_count"
