#!/usr/bin/env bash

sync_configs() {
  log "=== 同步配置文件 ===" "$GREEN"
  
  local script_root
  script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local config_dir="$script_root/config"
  
  # 检查配置目录是否存在
  if [[ ! -d "$config_dir" ]]; then
    log "配置目录不存在: $config_dir" "$RED"
    return 1
  fi
  
  # 创建 ~/.config 目录
  mkdir -p "$HOME/.config"
  
  # 通用配置
  symlink_config "$config_dir/nvim" "$HOME/.config/nvim"
  symlink_config "$config_dir/ranger" "$HOME/.config/ranger"
  symlink_config "$config_dir/tmuxinator" "$HOME/.config/tmuxinator"
  symlink_config "$config_dir/.zsh-utils" "$HOME/.config/.zsh-utils"
  
  symlink_config "$config_dir/.zshrc" "$HOME/.zshrc"
  symlink_config "$config_dir/.p10k.zsh" "$HOME/.p10k.zsh"
  symlink_config "$config_dir/.tmux.conf" "$HOME/.tmux.conf"
  symlink_config "$config_dir/.agignore" "$HOME/.agignore"
  
  # fzf-git
  mkdir -p "$HOME/fzf-addons"
  symlink_config "$config_dir/fzf-git/fzf-git.sh" "$HOME/fzf-addons/fzf-git.sh"
  
  # 平台专属配置
  if is_macos; then
    sync_macos_configs "$config_dir"
  fi
}

sync_macos_configs() {
  local config_dir="$1"
  
  # lazygit
  local lazygit_dir="$HOME/Library/Application Support/jesseduffield/lazygit"
  mkdir -p "$lazygit_dir"
  symlink_config "$config_dir/lazygit/config.yml" "$lazygit_dir/config.yml"
  
  # macOS 专属工具配置
  symlink_config "$config_dir/karabiner" "$HOME/.config/karabiner"
  symlink_config "$config_dir/yabai" "$HOME/.config/yabai"
  symlink_config "$config_dir/.hammerspoon" "$HOME/.hammerspoon"
  symlink_config "$config_dir/ghostty" "$HOME/.config/ghostty"
}

sync_configs
