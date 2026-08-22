#!/usr/bin/env bash

json_escape() {
  local value="${1:-}"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

json_string() {
  printf '"%s"' "$(json_escape "${1:-}")"
}

json_error() {
  local operation="$1"
  local status="$2"
  local code="$3"
  local message="$4"

  printf '{"schemaVersion":"1","operation":'
  json_string "$operation"
  printf ',"status":'
  json_string "$status"
  printf ',"error":{"code":'
  json_string "$code"
  printf ',"message":'
  json_string "$message"
  printf '}}\n'
}
