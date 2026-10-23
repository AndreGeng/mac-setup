# Neovim Rust support

The configuration enables rust-analyzer through Neovim's existing LSP integration,
Rust Treesitter parsing, and rustfmt through Conform's save formatting. Rust diagnostics
use Clippy. No additional Rust editor plugin is required.
File watching runs in rust-analyzer to avoid exhausting Neovim's file descriptors
when loading Rust standard library sources.

For an existing rustup installation, run the following from the Rust project's directory
(use the absolute path to `bin/mac-setup` if necessary):

```bash
./bin/mac-setup plan vim --with rust-tools --format json
./bin/mac-setup apply vim --with rust-tools --plan-id <id> \
  --allow network --non-interactive --format json
./bin/mac-setup verify vim --with rust-tools --format json
```

Review all `requiredApprovals` in the plan before applying. The normal editor capability
also reconciles its pinned Neovim, Treesitter CLI, Go, and gopls versions. Add other approval
flags only when required by the reviewed plan.

`rust-tools` adds `rust-analyzer`, `rust-src`, `rustfmt`, and `clippy` to the existing
active rustup toolchain. It does not install rustup, update Rust, or change the default
toolchain. rustup verifies its component downloads. A project using a different toolchain
needs these components installed for that toolchain too; run the flow in that project.
Neovim includes `~/.cargo/bin` in its PATH so rustup proxies work without shell activation.
Rust toolchains must provide the requested components.

Restart Neovim after applying. In a Rust file inside a Cargo project:

- `gd`: definition; `gi`: implementation; `K`: hover documentation.
- `grr`: references; `,rn`: rename; `,ca`: code actions.
- Saving runs rustfmt. `:FormatDisable` / `:FormatEnable` toggle save formatting.
- `:checkhealth vim.lsp` shows language service status.

Regression checks use temporary files and do not download dependencies:

```bash
bash test/nvim-rust-test.sh
bash test/nvim-rust-test.sh --integration
```

The integration check requires existing nvim-lspconfig and conform.nvim checkouts under
Neovim's standard Lazy data directory, and an already configured Rust toolchain. It checks
real rust-analyzer attachment, `gd` across modules, and save formatting in an offline Cargo
project. Treesitter parser installation uses the existing Neovim plugin bootstrap flow.
