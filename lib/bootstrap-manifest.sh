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
