# AGENTS.md

## Repo Structure

- `install.sh` — idempotent installer; clone and run manually
- `.zshrc` — main shell config (symlinked to `~/.zshrc`)
- `.config/starship.toml` — prompt config (symlinked to `~/.config/starship.toml`)
- Plugins installed to `~/.local/share/zsh/` (not managed by plugin managers)

## Dependencies

Installed via `install.sh` if missing:
- `ripgrep` (rg) — aliased as `grep` with `--color=auto --smart-case`
- `fzf` — fuzzy search only (no fzf-tab)
- `zoxide` — `z`/`j` aliases for smart cd
- `starship` — cross-shell prompt
- `vim` — git default editor (`GIT_EDITOR=vim`)

Package managers: Homebrew (macOS) or apt (Linux).

## Key Conventions

- Plugins sourced conditionally: `if [[ -f "$plugin_path" ]]; then source ...`
- Aliases for nicer tools are conditional: `if (( $+commands[bat] )); then alias cat='bat'; fi`
- Version managers (rbenv, pyenv, nvm) only initialized if already installed
- fzf key-bindings loaded from Homebrew path; fallback widget defined for other installations

## Development Commands

```bash
# Install / update
bash install.sh

# Non-interactive install
NONINTERACTIVE=1 bash install.sh

# Skip plugin auto-update
NO_AUTO_UPDATE=1 bash install.sh
```

## Things an Agent Would Miss

- fzf-tab was removed; standard zsh completion is used
- ripgrep replaces grep via alias (not overwriting grep binary)
- `grep` alias only set when `rg` command exists
- Homebrew's gnubin path for grep is no longer needed (ripgrep takes precedence)
- `GIT_EDITOR=vim` set in `.zshrc` for git interactive operations