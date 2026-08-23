#!/usr/bin/env bash

mise_bootstrap_manifest_path() {
  printf '%s\n' "$1/config/bootstrap/mise.tsv"
}

validate_mise_bootstrap_manifest() {
  local repo_root="$1"
  local manifest line version os_name arch filename sha256 extra key
  local pinned_version="" seen='|' record_count=0
  manifest="$(mise_bootstrap_manifest_path "$repo_root")"

  [[ -f "$manifest" ]] || {
    printf 'mise bootstrap manifest is missing: %s\n' "$manifest" >&2
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch filename sha256 extra <<<"$line"
    if [[ -z "$version" || -z "$os_name" || -z "$arch" || -z "$filename" ||
      -z "$sha256" || -n "$extra" ]]; then
      printf 'Invalid mise bootstrap manifest record.\n' >&2
      return 1
    fi
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
      printf 'mise bootstrap manifest requires an exact version.\n' >&2
      return 1
    }
    case "$os_name:$arch" in
    macos:arm64 | macos:x64 | linux:arm64 | linux:x64) ;;
    *)
      printf 'Unsupported platform in mise bootstrap manifest.\n' >&2
      return 1
      ;;
    esac
    [[ "$filename" == "mise-v${version}-${os_name}-${arch}.tar.gz" ]] || {
      printf 'mise bootstrap filename does not match its platform.\n' >&2
      return 1
    }
    [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || {
      printf 'mise bootstrap manifest requires a lowercase SHA-256 digest.\n' >&2
      return 1
    }
    if [[ -n "$pinned_version" && "$version" != "$pinned_version" ]]; then
      printf 'mise bootstrap manifest must pin one version.\n' >&2
      return 1
    fi
    pinned_version="$version"
    key="$os_name:$arch"
    [[ "$seen" != *"|$key|"* ]] || {
      printf 'Duplicate platform in mise bootstrap manifest.\n' >&2
      return 1
    }
    seen="${seen}${key}|"
    record_count=$((record_count + 1))
  done <"$manifest"

  [[ $record_count -eq 4 &&
    "$seen" == *'|macos:arm64|'* &&
    "$seen" == *'|macos:x64|'* &&
    "$seen" == *'|linux:arm64|'* &&
    "$seen" == *'|linux:x64|'* ]] || {
    printf 'mise bootstrap manifest must cover every supported platform.\n' >&2
    return 1
  }
}

mise_bootstrap_record() {
  local repo_root="$1"
  local requested_os="$2"
  local requested_arch="$3"
  local line version os_name arch filename sha256
  local manifest
  validate_mise_bootstrap_manifest "$repo_root" || return 1
  manifest="$(mise_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch filename sha256 <<<"$line"
    [[ "$os_name" == "$requested_os" && "$arch" == "$requested_arch" ]] || continue
    printf '%s|%s|%s\n' "$version" "$filename" "$sha256"
    return 0
  done <"$manifest"
  return 1
}

mise_bootstrap_version() {
  local repo_root="$1"
  local line version ignored
  local manifest
  validate_mise_bootstrap_manifest "$repo_root" || return 1
  manifest="$(mise_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version ignored <<<"$line"
    printf '%s\n' "$version"
    return 0
  done <"$manifest"
  return 1
}

neovim_bootstrap_manifest_path() {
  printf '%s\n' "$1/config/bootstrap/neovim.tsv"
}

neovim_bootstrap_filename() {
  local os_name="$1"
  local arch="$2"

  case "$os_name:$arch" in
  macos:arm64) printf '%s\n' nvim-macos-arm64.tar.gz ;;
  macos:x64) printf '%s\n' nvim-macos-x86_64.tar.gz ;;
  linux:arm64) printf '%s\n' nvim-linux-arm64.tar.gz ;;
  linux:x64) printf '%s\n' nvim-linux-x86_64.tar.gz ;;
  *) return 1 ;;
  esac
}

validate_neovim_bootstrap_manifest() {
  local repo_root="$1"
  local manifest line version os_name arch filename sha256 extra key expected_filename
  local pinned_version="" seen='|' record_count=0
  manifest="$(neovim_bootstrap_manifest_path "$repo_root")"

  [[ -f "$manifest" ]] || {
    printf 'Neovim bootstrap manifest is missing: %s\n' "$manifest" >&2
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch filename sha256 extra <<<"$line"
    if [[ -z "$version" || -z "$os_name" || -z "$arch" || -z "$filename" ||
      -z "$sha256" || -n "$extra" ]]; then
      printf 'Invalid Neovim bootstrap manifest record.\n' >&2
      return 1
    fi
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
      printf 'Neovim bootstrap manifest requires an exact version.\n' >&2
      return 1
    }
    expected_filename="$(neovim_bootstrap_filename "$os_name" "$arch")" || {
      printf 'Unsupported platform in Neovim bootstrap manifest.\n' >&2
      return 1
    }
    [[ "$filename" == "$expected_filename" ]] || {
      printf 'Neovim bootstrap filename does not match its platform.\n' >&2
      return 1
    }
    [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || {
      printf 'Neovim bootstrap manifest requires a lowercase SHA-256 digest.\n' >&2
      return 1
    }
    if [[ -n "$pinned_version" && "$version" != "$pinned_version" ]]; then
      printf 'Neovim bootstrap manifest must pin one version.\n' >&2
      return 1
    fi
    pinned_version="$version"
    key="$os_name:$arch"
    [[ "$seen" != *"|$key|"* ]] || {
      printf 'Duplicate platform in Neovim bootstrap manifest.\n' >&2
      return 1
    }
    seen="${seen}${key}|"
    record_count=$((record_count + 1))
  done <"$manifest"

  [[ $record_count -eq 4 &&
    "$seen" == *'|macos:arm64|'* &&
    "$seen" == *'|macos:x64|'* &&
    "$seen" == *'|linux:arm64|'* &&
    "$seen" == *'|linux:x64|'* ]] || {
    printf 'Neovim bootstrap manifest must cover every supported platform.\n' >&2
    return 1
  }
}

neovim_bootstrap_record() {
  local repo_root="$1"
  local requested_os="$2"
  local requested_arch="$3"
  local line version os_name arch filename sha256
  local manifest
  validate_neovim_bootstrap_manifest "$repo_root" || return 1
  manifest="$(neovim_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch filename sha256 <<<"$line"
    [[ "$os_name" == "$requested_os" && "$arch" == "$requested_arch" ]] || continue
    printf '%s|%s|%s\n' "$version" "$filename" "$sha256"
    return 0
  done <"$manifest"
  return 1
}

neovim_bootstrap_version() {
  local repo_root="$1"
  local line version ignored
  local manifest
  validate_neovim_bootstrap_manifest "$repo_root" || return 1
  manifest="$(neovim_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version ignored <<<"$line"
    printf '%s\n' "$version"
    return 0
  done <"$manifest"
  return 1
}

tree_sitter_bootstrap_manifest_path() {
  printf '%s\n' "$1/config/bootstrap/tree-sitter.tsv"
}

tree_sitter_bootstrap_filename() {
  local os_name="$1"
  local arch="$2"

  case "$os_name:$arch" in
  macos:arm64) printf '%s\n' tree-sitter-cli-macos-arm64.zip ;;
  macos:x64) printf '%s\n' tree-sitter-cli-macos-x64.zip ;;
  *) return 1 ;;
  esac
}

validate_tree_sitter_bootstrap_manifest() {
  local repo_root="$1"
  local manifest line version os_name arch method artifact sha256 build_runtime extra
  local key expected_artifact
  local pinned_version="" seen='|' record_count=0
  manifest="$(tree_sitter_bootstrap_manifest_path "$repo_root")"

  [[ -f "$manifest" ]] || {
    printf 'tree-sitter bootstrap manifest is missing: %s\n' "$manifest" >&2
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch method artifact sha256 build_runtime extra \
      <<<"$line"
    if [[ -z "$version" || -z "$os_name" || -z "$arch" || -z "$method" ||
      -z "$artifact" || -z "$sha256" || -z "$build_runtime" || -n "$extra" ]]; then
      printf 'Invalid tree-sitter bootstrap manifest record.\n' >&2
      return 1
    fi
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
      printf 'tree-sitter bootstrap manifest requires an exact version.\n' >&2
      return 1
    }
    case "$os_name:$arch" in
    macos:arm64 | macos:x64 | linux:arm64 | linux:x64) ;;
    *)
      printf 'Unsupported platform in tree-sitter bootstrap manifest.\n' >&2
      return 1
      ;;
    esac
    if [[ "$os_name" == "macos" ]]; then
      expected_artifact="$(tree_sitter_bootstrap_filename "$os_name" "$arch")" || return 1
      [[ "$method" == "github-release" && "$artifact" == "$expected_artifact" &&
        "$build_runtime" == "-" ]] || {
        printf 'tree-sitter macOS bootstrap record is invalid.\n' >&2
        return 1
      }
    else
      expected_artifact="tree-sitter-cli-${version}.crate"
      [[ "$method" == "crates-io" && "$artifact" == "$expected_artifact" &&
        "$build_runtime" =~ ^rust@[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
        printf 'tree-sitter Linux bootstrap record is invalid.\n' >&2
        return 1
      }
    fi
    [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || {
      printf 'tree-sitter bootstrap manifest requires a lowercase SHA-256 digest.\n' >&2
      return 1
    }
    if [[ -n "$pinned_version" && "$version" != "$pinned_version" ]]; then
      printf 'tree-sitter bootstrap manifest must pin one version.\n' >&2
      return 1
    fi
    pinned_version="$version"
    key="$os_name:$arch"
    [[ "$seen" != *"|$key|"* ]] || {
      printf 'Duplicate platform in tree-sitter bootstrap manifest.\n' >&2
      return 1
    }
    seen="${seen}${key}|"
    record_count=$((record_count + 1))
  done <"$manifest"

  [[ $record_count -eq 4 &&
    "$seen" == *'|macos:arm64|'* &&
    "$seen" == *'|macos:x64|'* &&
    "$seen" == *'|linux:arm64|'* &&
    "$seen" == *'|linux:x64|'* ]] || {
    printf 'tree-sitter bootstrap manifest must cover every supported platform.\n' >&2
    return 1
  }
}

tree_sitter_bootstrap_record() {
  local repo_root="$1"
  local requested_os="$2"
  local requested_arch="$3"
  local line version os_name arch method artifact sha256 build_runtime
  local manifest
  validate_tree_sitter_bootstrap_manifest "$repo_root" || return 1
  manifest="$(tree_sitter_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version os_name arch method artifact sha256 build_runtime <<<"$line"
    [[ "$os_name" == "$requested_os" && "$arch" == "$requested_arch" ]] || continue
    printf '%s|%s|%s|%s|%s\n' \
      "$version" "$method" "$artifact" "$sha256" "$build_runtime"
    return 0
  done <"$manifest"
  return 1
}

tree_sitter_bootstrap_version() {
  local repo_root="$1"
  local line version ignored
  local manifest
  validate_tree_sitter_bootstrap_manifest "$repo_root" || return 1
  manifest="$(tree_sitter_bootstrap_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r version ignored <<<"$line"
    printf '%s\n' "$version"
    return 0
  done <"$manifest"
  return 1
}
