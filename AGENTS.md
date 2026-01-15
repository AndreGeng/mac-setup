# AGENTS.md

This file contains guidelines for agentic coding agents working in this macOS development environment setup repository.

## Project Overview

This is a modular macOS development environment setup repository using shell scripts for automation. The project installs and configures development tools, applications, and dotfiles using Homebrew, Mise, and symlink management.

## Commands

### Setup and Installation
```bash
# Main setup script - runs all components in sequence
./setup.sh

# Individual component scripts
./brew.sh          # Homebrew packages and cask applications
./nodejs.sh        # Node.js via Mise with global npm packages
./zsh.sh           # Zsh shell with Oh My Zsh and Zinit
./vim.sh           # Neovim with Python environments
./tmux.sh          # tmux terminal multiplexer configuration
./sync.sh          # Creates symlinks for configuration files
./karabiner.sh     # Karabiner-Elements keyboard remapping
```

### Development Tools
```bash
# Shell script formatting
shfmt -w -i 2 script.sh

# Lua formatting (Neovim configs)
stylua --config-path mac-config/nvim/stylua.toml mac-config/nvim/

# Python formatting
black mac-config/ranger/plugins/
isort mac-config/ranger/plugins/

# General formatting
prettier --write .  # For JSON/YAML/Markdown files
```

### Testing
This repository does not have traditional tests. To validate changes:
1. Run the specific script you modified (e.g., `./brew.sh`)
2. Verify the expected installations/configurations are present
3. Check symlinks with `ls -la ~/.config/` or similar directories

## Code Style Guidelines

### Shell Scripts (.sh files)
- **Shebang**: Use `#!/bin/bash` or `#!/usr/bin/env bash`
- **Utility Loading**: All scripts must source utilities:
  ```bash
  for f in $(dirname "$0")/utils/*.sh; do
    source $f
  done
  ```
- **Logging**: Use the standardized `log()` function with color constants:
  ```bash
  log "Installation complete" $GREEN
  log "Error occurred" $RED
  ```
- **Error Checking**: Use utility functions for existence checks:
  ```bash
  command_exists "brew" || install_homebrew_if_needed
  ```
- **Indentation**: 2 spaces
- **Line Length**: Prefer under 100 characters

### Lua Configuration (Neovim)
- **Structure**: Modular configuration in `lua/plugins/` and `lua/config/`
- **Plugin Spec**: Use the standard LazyVim plugin format:
  ```lua
  return {
    'plugin/name',
    dependencies = { 'dependency' },
    config = function()
      -- configuration
    end
  }
  ```
- **Indentation**: 2 spaces
- **Formatting**: Use stylua with project config

### YAML Configuration
- **Indentation**: 2 spaces for most files (tmux, alacritty)
- **Quotes**: Use single quotes for strings unless variable substitution is needed
- **Comments**: Use `#` for comments, align with content when possible

### Python (Ranger plugins)
- **Style**: Follow PEP 8
- **Formatting**: Use black and isort
- **Imports**: Group imports (standard library, third-party, local)

## File Organization

### Script Structure
- `setup.sh` - Main orchestrator
- `*.sh` - Component installation scripts
- `utils/*.sh` - Shared utility functions
- `mac-config/` - Configuration files to be symlinked
- `mac-config/nvim/` - Neovim Lua configuration

### Configuration Management
- All user configs live in `mac-config/`
- Use `sync.sh` to create symlinks to home directory
- Maintain the same directory structure in `~/.config/`

## Naming Conventions

### Files and Directories
- **Scripts**: kebab-case (e.g., `nodejs.sh`, `karabiner.sh`)
- **Utilities**: descriptive names with prefixes (e.g., `1.constants.sh`, `2.log.sh`)
- **Configs**: Use original application names (e.g., `nvim/`, `alacritty/`)

### Variables and Functions
- **Shell Variables**: UPPER_CASE for constants, lower_case for variables
- **Functions**: snake_case with descriptive names
- **Lua**: snake_case for variables and functions

## Error Handling

### Shell Scripts
- Always check for command existence before using
- Use the `log()` function for user feedback
- Provide meaningful error messages with colors
- Use `||` chaining for fallback behavior

### Configuration Files
- Validate configurations when possible
- Use conditional sections for different environments
- Provide fallback values for optional settings

## Import and Dependency Management

### Shell Scripts
- Source utilities at the beginning of each script
- Check for external dependencies before use
- Use Homebrew for package management when possible

### Neovim Configuration
- Use LazyVim for plugin management
- Declare dependencies explicitly in plugin specs
- Use `require()` for modular configuration

### Node.js
- Managed via Mise (`mise use node@lts`)
- Global packages installed in `nodejs.sh`
- Use npm for package management

## Security Considerations

- Never commit sensitive data (API keys, passwords)
- Use environment variables for configuration when needed
- Validate user input in scripts
- Use `sudo` sparingly and only when necessary

## Platform-Specific Guidelines

### macOS
- Use Homebrew for package management
- Respect macOS file system permissions
- Use macOS-specific paths (e.g., `~/Library/Application Support/`)
- Handle application installation via casks when possible

### Cross-Platform Considerations
- Use POSIX-compliant shell syntax when possible
- Provide fallbacks for macOS-specific commands
- Document platform-specific requirements

## Common Patterns

### Installation Pattern
```bash
#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

command_exists "tool" || {
  log "Installing tool..." $YELLOW
  brew install tool
  log "Tool installed" $GREEN
}
```

### Configuration Pattern
```bash
# Create config directory if needed
mkdir -p ~/.config/app

# Symlink configuration
ln -sf "$(pwd)/mac-config/app/config" ~/.config/app/config
```

### Plugin Configuration Pattern (Lua)
```lua
return {
  'plugin/name',
  config = function()
    require('plugin').setup({
      option = value,
    })
  end
}
```

## Notes for AI Agents

- This is a setup repository, not a software project - focus on configuration and automation
- Test changes by running individual scripts, not the full setup
- Preserve the modular architecture - don't merge scripts
- Use existing utility functions rather than reimplementing
- Maintain compatibility with the user's existing dotfiles
- Consider the order of operations - some tools depend on others