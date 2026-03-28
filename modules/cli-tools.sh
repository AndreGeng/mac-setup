#!/usr/bin/env bash

install_cli_tools() {
  log "=== 安装 CLI 工具 ===" "$GREEN"
  
  # 通用工具列表
  local tools=(
    "lazygit"
    "the_silver_searcher"
    "git-delta"
    "ast-grep"
    "shfmt"
  )
  
  for tool in "${tools[@]}"; do
    local cmd_name="${tool%%-*}"
    if ! command -v "$cmd_name" &>/dev/null && ! command -v "$tool" &>/dev/null; then
      pkg_install "$tool" || log "跳过 $tool (可能需要 root)" "$YELLOW"
    else
      log "$tool 已安装，跳过" "$YELLOW"
    fi
  done
  
  # fzf 键绑定
  install_fzf_keybindings
}

install_fzf_keybindings() {
  local fzf_dir="$HOME/.fzf"
  
  if [[ ! -d "$fzf_dir" ]]; then
    log "安装 fzf 键绑定..." "$GREEN"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$fzf_dir"
    "$fzf_dir/install" --key-bindings --completion --no-update-rc
  else
    log "fzf 键绑定已安装，跳过" "$YELLOW"
  fi
}

install_cli_tools
