#!/usr/bin/env bash

install_linux_fonts() {
  log "=== 安装 Linux 字体 ===" "$GREEN"
  
  local font_dir="$HOME/.local/share/fonts"
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
  local font_name="Hack Regular Nerd Font Complete.ttf"
  
  if [[ -f "$font_dir/$font_name" ]]; then
    log "字体已安装，跳过" "$YELLOW"
    return 0
  fi
  
  mkdir -p "$font_dir"
  
  local tmp_dir
  tmp_dir=$(mktemp -d)
  log "下载 Hack Nerd Font..." "$GREEN"
  
  if curl -fLo "$tmp_dir/Hack.zip" "$font_url"; then
    unzip -o "$tmp_dir/Hack.zip" -d "$tmp_dir" >/dev/null 2>&1
    cp "$tmp_dir/"*.ttf "$font_dir/" 2>/dev/null || true
    rm -rf "$tmp_dir"
    
    # 刷新字体缓存
    if command -v fc-cache &>/dev/null; then
      fc-cache -fv "$font_dir"
    fi
    
    log "字体安装完成" "$GREEN"
  else
    log "字体下载失败" "$RED"
    rm -rf "$tmp_dir"
    return 1
  fi
}

install_linux_fonts
