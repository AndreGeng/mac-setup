#!/usr/bin/env bash
#
# OpenCode 模块：安装 OpenCode CLI 并配置
#

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in "$SCRIPT_ROOT/../utils"/*.sh; do
  source "$f"
done

if command_exists "opencode"; then
  log "OpenCode is already installed" "$GREEN"
  log "Current version: $(opencode --version 2>/dev/null || echo 'unknown')" "$CYAN"
else
  log "Installing OpenCode..." "$YELLOW"

  if command_exists "brew"; then
    log "Installing OpenCode via Homebrew..." "$YELLOW"
    brew install anomalyco/tap/opencode || {
      log "Homebrew installation failed, trying npm..." "$YELLOW"
      if command_exists "npm"; then
        npm install -g opencode-ai
      else
        log "Neither Homebrew nor npm found." "$RED"
        exit 1
      fi
    }
  elif command_exists "npm"; then
    log "Installing OpenCode via npm..." "$YELLOW"
    npm install -g opencode-ai
  else
    log "Neither Homebrew nor npm found." "$RED"
    exit 1
  fi

  if command_exists "opencode"; then
    log "OpenCode installed successfully!" "$GREEN"
  else
    log "OpenCode installation failed" "$RED"
    exit 1
  fi
fi

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
mkdir -p "$OPENCODE_CONFIG_DIR"

log "Setting up OpenCode configuration..." "$YELLOW"

cat >"$OPENCODE_CONFIG_DIR/opencode.json" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "Mify-Zhipu/zhipuai/glm-5",
  "theme": "dark",
  "autoupdate": true,
  "plugin": ["opencode-swarm"],
  "formatter": {
    "shfmt": {
      "command": ["shfmt", "-w", "-i", "2", "$FILE"],
      "extensions": [".sh", ".bash"]
    },
    "stylua": {
      "command": ["stylua", "--config-path", "config/nvim/stylua.toml", "$FILE"],
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
        "apiKey": "{env:MIFY_API_KEY}",
        "baseURL": "{env:MIFY_API_URL}"
      }
    },
    "Mify-Zhipu": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Zhipu",
      "options": {
        "baseURL": "{env:MIFY_API_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
      },
      "models": {
        "zhipuai/glm-4.7": {
          "name": "zhipuai/glm-4.7"
        },
        "zhipuai/glm-5": {
          "name": "zhipuai/glm-5"
        }
      }
    },
    "Mify-OpenAI": {
      "npm": "@ai-sdk/openai",
      "name": "Mify-OpenAI",
      "options": {
        "baseURL": "{env:MIFY_API_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
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
        "baseURL": "{env:MIFY_API_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
      },
      "models": {
        "xiaomi/mimo-v2-flash": {
          "name": "xiaomi/mimo-v2-flash"
        },
        "xiaomi/mimo-v2-pro:": {
          "name": "xiaomi/mimo-v2-pro"
        }
      }
    },
    "Mify-Kimi": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Kimi",
      "options": {
        "baseURL": "{env:MIFY_API_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
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
        "baseURL": "{env:MIFY_API_SGP_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
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
    },
    "Mify-Anthropic": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Mify-Anthropic",
      "options": {
        "baseURL": "{env:MIFY_API_URL}",
        "apiKey": "{env:MIFY_API_KEY}"
      },
      "models": {
        "ppio/pa/claude-opus-4-6": {
          "name": "ppio/pa/claude-opus-4-6",
          "modalities": {
            "input": ["text", "image"],
            "output": ["text"]
          }
        },
        "ppio/pa/claude-sonnet-4-6": {
          "name": "ppio/pa/claude-sonnet-4-6",
          "modalities": {
            "input": ["text", "image"],
            "output": ["text"]
          }
        },
        "ppio/pa/claude-haiku-4-5-20251001": {
          "name": "ppio/pa/claude-haiku-4-5-20251001",
          "modalities": {
            "input": ["text", "image"],
            "output": ["text"]
          }
        }
      }
    }
  }
}
EOF

add_opencode_alias() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    if ! grep -q "alias oc=" "$config_file" 2>/dev/null; then
      cat >>"$config_file" <<'ALIAS'

# OpenCode AI Coding Agent Aliases
alias oc="opencode"
alias oc-init="opencode && /init"
alias oc-share="opencode && /share"
ALIAS
      log "Added OpenCode aliases to $config_file" "$GREEN"
    else
      log "OpenCode aliases already exist in $config_file" "$CYAN"
    fi
  fi
}

add_opencode_alias "$HOME/.zshrc"
add_opencode_alias "$HOME/.bashrc"
add_opencode_alias "$HOME/.bash_profile"

if command_exists "npm"; then
  if ! command_exists "bash-language-server"; then
    log "Installing bash-language-server..." "$YELLOW"
    npm install -g bash-language-server
  fi
  if ! command_exists "yaml-language-server"; then
    log "Installing yaml-language-server..." "$YELLOW"
    npm install -g yaml-language-server
  fi
fi

log "OpenCode module completed!" "$GREEN"
