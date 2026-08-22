#!/usr/bin/env bash

node_manifest_path() {
  printf '%s\n' "$1/config/runtime/node.tsv"
}

validate_node_manifest() {
  local repo_root="$1"
  local manifest
  local line kind name version extra key seen='|'
  local node_count=0 bun_count=0 npm_count=0
  manifest="$(node_manifest_path "$repo_root")"

  [[ -f "$manifest" ]] || {
    printf 'Node runtime manifest is missing: %s\n' "$manifest" >&2
    return 1
  }

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r kind name version extra <<<"$line"
    if [[ -z "$kind" || -z "$name" || -z "$version" || -n "$extra" ]]; then
      printf 'Invalid Node runtime manifest record.\n' >&2
      return 1
    fi
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || {
      printf 'Node runtime manifest requires exact versions.\n' >&2
      return 1
    }
    case "$kind" in
    runtime)
      case "$name" in
      node) node_count=$((node_count + 1)) ;;
      bun) bun_count=$((bun_count + 1)) ;;
      *)
        printf 'Unknown runtime in Node manifest.\n' >&2
        return 1
        ;;
      esac
      ;;
    npm)
      [[ "$name" =~ ^(@[0-9A-Za-z._-]+/)?[0-9A-Za-z._-]+$ ]] || {
        printf 'Invalid npm package name in Node manifest.\n' >&2
        return 1
      }
      npm_count=$((npm_count + 1))
      ;;
    *)
      printf 'Unknown record type in Node manifest.\n' >&2
      return 1
      ;;
    esac
    key="$kind:$name"
    [[ "$seen" != *"|$key|"* ]] || {
      printf 'Duplicate dependency in Node runtime manifest.\n' >&2
      return 1
    }
    seen="${seen}${key}|"
  done <"$manifest"

  [[ $node_count -eq 1 && $bun_count -eq 1 && $npm_count -gt 0 ]] || {
    printf 'Node runtime manifest is incomplete.\n' >&2
    return 1
  }
}

node_manifest_records() {
  local repo_root="$1"
  local requested_kind="$2"
  local line kind name version
  local manifest
  manifest="$(node_manifest_path "$repo_root")"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != \#* ]] || continue
    IFS=$'\t' read -r kind name version <<<"$line"
    [[ "$kind" == "$requested_kind" ]] || continue
    printf '%s|%s\n' "$name" "$version"
  done <"$manifest"
}

node_manifest_version() {
  local repo_root="$1"
  local requested_kind="$2"
  local requested_name="$3"
  local name version
  while IFS='|' read -r name version; do
    [[ "$name" == "$requested_name" ]] || continue
    printf '%s\n' "$version"
    return 0
  done < <(node_manifest_records "$repo_root" "$requested_kind")
  return 1
}
