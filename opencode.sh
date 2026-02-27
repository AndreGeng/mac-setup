#!/bin/bash
# OpenCode Setup Script for macOS Development Environment
# This script installs and configures OpenCode AI coding agent

for f in $(dirname "$0")/utils/*.sh; do
  source $f
done

# Check if OpenCode is already installed
if exists "opencode"; then
  log "OpenCode is already installed" $GREEN
  log "Current version: $(opencode --version 2>/dev/null || echo 'unknown')" $CYAN
else
  log "Installing OpenCode..." $YELLOW

  # Install via Homebrew (preferred method)
  if exists "brew"; then
    log "Installing OpenCode via Homebrew..." $YELLOW
    brew install anomalyco/tap/opencode || {
      log "Homebrew installation failed, trying npm..." $YELLOW
      # Fallback to npm installation
      if exists "npm"; then
        npm install -g opencode-ai
      else
        log "Neither Homebrew nor npm found. Please install one first." $RED
        exit 1
      fi
    }
  else
    # Install via npm if Homebrew is not available
    if exists "npm"; then
      log "Installing OpenCode via npm..." $YELLOW
      npm install -g opencode-ai
    else
      log "Neither Homebrew nor npm found. Please install one first." $RED
      exit 1
    fi
  fi

  # Verify installation
  if exists "opencode"; then
    log "OpenCode installed successfully!" $GREEN
    log "Version: $(opencode --version 2>/dev/null || echo 'unknown')" $CYAN
  else
    log "OpenCode installation failed" $RED
    exit 1
  fi
fi

# Create OpenCode configuration directory
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

# Create basic OpenCode configuration
log "Setting up OpenCode configuration..." $YELLOW

# Create config file with recommended settings for this repository
cat >"$OPENCODE_CONFIG_DIR/opencode.json" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "Mify-Zhipu/zhipuai/glm-4.7",
  "theme": "dark",
  "autoupdate": true,
  "formatter": {
    "shfmt": {
      "command": ["shfmt", "-w", "-i", "2", "$FILE"],
      "extensions": [".sh", ".bash"]
    },
    "stylua": {
      "command": ["stylua", "--config-path", "mac-config/nvim/stylua.toml", "$FILE"],
      "extensions": [".lua"]
    },
    "black": {
      "command": ["black", "$FILE"],
      "extensions": [".py"]
    },
    "isort": {
      "command": ["isort", "$FILE"],
      "extensions": [".py"]
    },
    "prettier": {
      "command": ["prettier", "--write", "$FILE"],
      "extensions": [".js", ".ts", ".jsx", ".tsx", ".json", ".yaml", ".yml", ".md"]
    }
  },
  "command": {
    "test": {
      "template": "Run tests and validate setup",
      "description": "Test shell scripts and configuration"
    },
    "format": {
      "template": "Format all code files using appropriate formatters",
      "description": "Format shell scripts, lua, python, and web files"
    }
  },
  "instructions": ["AGENTS.md"],
  "watcher": {
    "ignore": ["node_modules/**", "dist/**", ".git/**", "*.tmp"]
  },
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest"]
    },
    "feishu-mcp": {
      "type": "remote",
      "url": "https://open.feishu.cn/mcp/stream/mcp__aQA3IxPLp5MwCLVlNU76kVAeMEhKxl4MwJOOIVhIGh0cRWNWke1K_Ah1nRKocC12Zg8qfMxks8"
    },
    "chrome-devtools": {
      "type": "local",
      "command": ["npx", "-y", "chrome-devtools-mcp@latest"]
    }
  },
  "provider": {
    "Mify-Minimax1": {
      "models": {
        "minimax/MiniMax-M2.5": {
          "name": "minimax/MiniMax-M2.5"
        }
      },
      "name": "Mify-Minimax",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "apiKey": "{env:MIMO_API_KEY}",
        "baseURL": "http://model.mify.ai.srv/v1/"
      }
    },
    "Mify-Zhipu": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Zhipu",
      "options": {
        "baseURL": "{env:MIMO_API_URL}",
        "apiKey": "{env:MIMO_API_KEY}"
      },
      "models": {
        "zhipuai/glm-4.7": {
          "name": "zhipuai/glm-4.7"
        }
      }
    },
    "Mify-OpenAI": {
      "npm": "@ai-sdk/openai",
      "name": "Mify-OpenAI",
      "options": {
        "baseURL": "{env:MIMO_API_URL}",
        "apiKey": "{env:MIMO_API_KEY}"
      },
      "models": {
        "azure_openai/gpt-5.1-codex": {
          "name": "azure_openai/gpt-5.1-codex"
        }
      }
    },
    "Mify-Xiaomi": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Xiaomi",
      "options": {
        "baseURL": "{env:MIMO_API_URL}",
        "apiKey": "{env:MIMO_API_KEY}"
      },
      "models": {
        "xiaomi/mimo-v2-flash": {
          "name": "xiaomi/mimo-v2-flash"
        }
      }
    },
    "Mify-Kimi": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Kimi",
      "options": {
        "baseURL": "{env:MIMO_API_URL}",
        "apiKey": "{env:MIMO_API_KEY}"
      },
      "models": {
        "volcengine_maas/kimi-k2-250711": {
          "name": "volcengine_maas/kimi-k2-250711"
        }
      }
    },
    "Mify-Google": {
      "npm": "@ai-sdk/google",
      "options": {
        "baseURL": "{env:MIMO_API_SGP_URL}",
        "apiKey": "{env:MIMO_API_KEY}"
      },
      "models": {
        "gemini-3-pro-preview-pt": {
          "name": "gemini-3-pro",
          "limit": {
            "context": 1000000,
            "output": 128000
          }
        },
        "gemini-3-flash-preview": {
          "name": "gemini-3-flash",
          "limit": {
            "context": 1000000,
            "output": 128000
          }
        }
      }
    }
  }
}
EOF

# Create OpenCode aliases in shell config
log "Adding OpenCode aliases to shell configuration..." $YELLOW

# Check for existing shell configs and add aliases
add_opencode_alias() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    # Check if alias already exists
    if ! grep -q "alias oc=" "$config_file" 2>/dev/null; then
      cat >>"$config_file" <<'EOF'

# OpenCode AI Coding Agent Aliases
alias oc="opencode"
alias oc-init="opencode && /init"
alias oc-share="opencode && /share"
EOF
      log "Added OpenCode aliases to $config_file" $GREEN
    else
      log "OpenCode aliases already exist in $config_file" $CYAN
    fi
  fi
}

# Add aliases to common shell configs
add_opencode_alias "$HOME/.zshrc"
add_opencode_alias "$HOME/.bashrc"
add_opencode_alias "$HOME/.bash_profile"

# Create a helpful OpenCode usage guide
log "Creating OpenCode usage guide..." $YELLOW
cat >"$OPENCODE_CONFIG_DIR/usage-guide.md" <<'EOF'
# OpenCode Usage Guide

## Quick Start
```bash
# Navigate to your project
cd /path/to/project

# Start OpenCode
opencode

# Initialize OpenCode for the project
/init
```

## Common Commands
- `/init` - Initialize OpenCode for current project
- `/share` - Share current session
- `/undo` - Undo last changes
- `/redo` - Redo undone changes
- `/connect` - Connect to AI provider

## Aliases (added to your shell)
- `oc` - Start OpenCode
- `oc-init` - Start OpenCode and initialize project
- `oc-share` - Start OpenCode and share session

## Tips for This Repository
- OpenCode is already configured with AGENTS.md guidelines
- Use `@` to reference files (e.g., `@setup.sh`)
- Ask about shell script patterns, Neovim config, or automation
- OpenCode understands the modular architecture and utility functions

## Configuration
- Config file: ~/.config/opencode/config.json
- LSP servers: bash-language-server, lua-language-server, yaml-language-server
- Formatters: shfmt, stylua, black, prettier
EOF

# Install language servers for better OpenCode experience
log "Installing language servers for enhanced OpenCode experience..." $YELLOW

# Install bash language server
if exists "npm"; then
  if ! exists "bash-language-server"; then
    log "Installing bash-language-server..." $YELLOW
    npm install -g bash-language-server
  fi
fi

# Install lua language server
if exists "brew"; then
  if ! exists "lua-language-server"; then
    log "Installing lua-language-server..." $YELLOW
    brew install lua-language-server
  fi
fi

# Install yaml language server
if exists "npm"; then
  if ! exists "yaml-language-server"; then
    log "Installing yaml-language-server..." $YELLOW
    npm install -g yaml-language-server
  fi
fi

# Final setup and verification
log "OpenCode setup completed!" $GREEN
log ""
log "Next steps:" $CYAN
log "1. Restart your terminal or run: source ~/.zshrc" $WHITE
log "2. Navigate to a project directory" $WHITE
log "3. Run: oc-init" $WHITE
log "4. Start coding with AI assistance!" $WHITE
log ""
log "Configuration files:" $CYAN
log "- OpenCode config: ~/.config/opencode/opencode.json" $WHITE
log "- Usage guide: ~/.config/opencode/usage-guide.md" $WHITE
log "- Project guidelines: ./AGENTS.md" $WHITE
log ""
log "Quick test: Run 'oc' to start OpenCode" $GREEN
