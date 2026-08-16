#!/usr/bin/env bash
set -euo pipefail

REPO="."
MODE="tracked"
RANGE=""

usage() {
  cat <<'EOF'
Usage: privacy-scan.sh [--repo PATH] [--staged | --untracked | --range REVISION_RANGE]

Scans tracked files for private paths, internal identifiers, and forbidden files.
Matched values are never printed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --repo)
    REPO="$2"
    shift 2
    ;;
  --staged)
    MODE="staged"
    shift
    ;;
  --untracked)
    MODE="untracked"
    shift
    ;;
  --range)
    MODE="range"
    RANGE="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf 'Unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

REPO="$(cd "$REPO" && pwd)"
IGNORE_FILE="$REPO/.privacyignore"
findings=0

is_ignored_legacy_path() {
  local path="$1"
  local prefix

  [[ "$MODE" == "tracked" && -f "$IGNORE_FILE" ]] || return 1
  while IFS=$'\t' read -r prefix _reason; do
    [[ -n "$prefix" && "$prefix" != \#* ]] || continue
    [[ "$path" == "$prefix"* ]] && return 0
  done <"$IGNORE_FILE"
  return 1
}

report() {
  local rule="$1"
  local path="$2"

  printf 'ERROR %-18s %s\n' "$rule" "$path" >&2
  findings=$((findings + 1))
}

forbidden_path_rule() {
  local path="$1"
  local basename="${path##*/}"

  case "$path" in
  */node_modules/* | node_modules/* | */site-packages/* | site-packages/* | \
    */sessions/* | sessions/* | */transcripts/* | transcripts/*)
    printf '%s' 'generated-or-session'
    return 0
    ;;
  esac

  case "$basename" in
  .env | .env.* | auth.json | credentials | credentials.json | \
    history.json | history.jsonl | *.sqlite | *.sqlite3 | *.db | *.pem | *.key | *.p12 | *.pfx)
    [[ "$basename" == ".env.example" ]] && return 1
    printf '%s' 'sensitive-file'
    return 0
    ;;
  esac
  return 1
}

scan_stream() {
  local path="$1"
  local content="$2"

  if printf '%s' "$content" | LC_ALL=C grep -Eq 'mcp__[A-Za-z0-9_-]{20,}'; then
    report 'mcp-token' "$path"
  fi
  if printf '%s' "$content" | LC_ALL=C grep -Eq '/Users/[A-Za-z0-9._-]+/'; then
    report 'personal-path' "$path"
  fi
  if printf '%s' "$content" | LC_ALL=C grep -Eiq '([A-Za-z0-9-]+\.)+srv([^A-Za-z0-9-]|$)|https?://[A-Za-z0-9._-]+\.(internal|corp)([^A-Za-z0-9-]|$)'; then
    report 'internal-domain' "$path"
  fi
  if printf '%s' "$content" | LC_ALL=C grep -Eiq '[A-Z0-9._%+-]+@(xiaomi|bytedance|meituan|innotechx)\.com|[A-Z0-9._%+-]+@[^[:space:]]*\.mioffice\.cn'; then
    report 'enterprise-email' "$path"
  fi
  return 0
}

scan_range() {
  local path=""
  local content=""
  local line
  local rule
  local in_metadata=false
  local expect_new_header=false

  while IFS= read -r line; do
    if [[ "$line" == 'diff --git '* ]]; then
      in_metadata=true
      expect_new_header=false
      continue
    fi

    if [[ "$in_metadata" == "true" && "$line" == '--- '* ]]; then
      expect_new_header=true
      continue
    fi

    if [[ "$expect_new_header" == "true" && "$line" == '+++ '* ]]; then
      if [[ -n "$path" ]]; then
        scan_stream "$path" "$content"
      fi
      path="${line#+++ }"
      content=""
      [[ "$path" == "/dev/null" ]] && path=""
      in_metadata=false
      expect_new_header=false
      continue
    fi

    case "$line" in
    '+'*)
      [[ -n "$path" ]] && content+="${line#+}"$'\n'
      ;;
    esac
  done < <(git -C "$REPO" diff --no-ext-diff --no-prefix --unified=0 "$RANGE")

  if [[ -n "$path" ]]; then
    scan_stream "$path" "$content"
  fi

  while IFS= read -r -d '' path; do
    if rule="$(forbidden_path_rule "$path")"; then
      report "$rule" "$path"
    fi
  done < <(git -C "$REPO" diff --name-only --diff-filter=ACMR -z "$RANGE")
}

scan_path() {
  local path="$1"
  local rule
  local content

  [[ -n "$path" ]] || return 0
  if is_ignored_legacy_path "$path"; then
    return 0
  fi

  if rule="$(forbidden_path_rule "$path")"; then
    report "$rule" "$path"
    return
  fi

  if [[ "$MODE" == "staged" ]]; then
    content="$(git -C "$REPO" show ":$path" 2>/dev/null || true)"
  else
    [[ -f "$REPO/$path" ]] || return 0
    LC_ALL=C grep -Iq . "$REPO/$path" 2>/dev/null || return 0
    content="$(<"$REPO/$path")"
  fi
  scan_stream "$path" "$content"
  return 0
}

case "$MODE" in
tracked)
  while IFS= read -r -d '' path; do
    scan_path "$path"
  done < <(git -C "$REPO" ls-files -z)
  ;;
staged)
  while IFS= read -r -d '' path; do
    scan_path "$path"
  done < <(git -C "$REPO" diff --cached --name-only --diff-filter=ACMR -z)
  ;;
untracked)
  while IFS= read -r -d '' path; do
    scan_path "$path"
  done < <(git -C "$REPO" ls-files --others --exclude-standard -z)
  ;;
range)
  [[ -n "$RANGE" ]] || {
    printf '%s\n' '--range requires a revision range' >&2
    exit 2
  }
  scan_range
  ;;
esac

if ((findings > 0)); then
  printf 'Privacy scan failed with %d finding(s). Values were redacted.\n' "$findings" >&2
  exit 1
fi

printf 'Privacy scan passed.\n'
