# nikky-cmd

Portable zsh environment for consistent configuration across macOS and Linux machines.

## Features

- **Starship** prompt — cross-shell, fast, configured via `starship.toml`
- **fzf** — fuzzy history search (`Ctrl+R`), file search (`Ctrl+T`), directory jump (`Alt+C`)
- **ripgrep** — `grep` aliased to `rg --color=auto --smart-case`
- **zsh-autosuggestions** — ghost-text command suggestions from history
- **zsh-syntax-highlighting** — real-time command coloring
- **zoxide** — smart directory jumping (`z` and `j` aliases)
- **Shared history** — 50K in-memory, 100K on-disk, consistent across sessions
- **Git aliases** — `g`, `gst`, `gc`, `gp`, `gl`, `gb`, `gco`, etc.
- **Colored man pages** — no plugin needed, just env vars
- **Conditional loading** — rbenv, pyenv, nvm only activated if installed

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/allynfolksjr/nikky-cmd/main/install.sh | bash
```

Or clone and run manually:

```bash
git clone https://github.com/allynfolksjr/nikky-cmd.git ~/Repositories/nikky-cmd
bash ~/Repositories/nikky-cmd/install.sh
```

Then start a new session:

```bash
exec zsh
```

## Requirements

- **zsh** (installed automatically if missing)
- **git** (for cloning plugins)
- **Homebrew** (macOS) or **apt** (Linux) for installing fzf, zoxide, and starship

## Directory Structure

```
nikky-cmd/
├── install.sh              # Installer script
├── .zshrc                  # Unified zsh configuration
├── .config/
│   └── starship.toml       # Starship prompt config
└── README.md
```

## Plugin Locations

All plugins are cloned to `~/.local/share/zsh/`:

| Plugin | Purpose |
|---|---|
| zsh-autosuggestions | Ghost-text history suggestions |
| zsh-syntax-highlighting | Command coloring |

## Updating

Re-run the installer — it's idempotent and will update all plugins:

```bash
bash ~/Repositories/nikky-cmd/install.sh
```

## Key Bindings

| Shortcut | Action |
|---|---|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search (fzf) |
| `Alt+C` | Fuzzy directory jump (fzf) |

## Aliases

### Git

| Alias | Command |
|---|---|
| `g` | `git` |
| `gst` | `git status` |
| `gc` / `gcm` | `git commit` / `git commit -m` |
| `gp` / `gpf` | `git push` / `git push --force-with-lease` |
| `gl` | `git pull` |
| `gb` / `gba` | `git branch -vv` / `git branch -avv` |
| `gco` / `gcb` | `git checkout` / `git checkout -b` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `ga` / `gaa` | `git add` / `git add -A` |
| `glog` / `gloga` | `git log` with graph |
| `grh` / `grhh` | `git reset HEAD` / `git reset HEAD --hard` |

### Other

| Alias | Command |
|---|---|
| `be` | `bundle exec` |
| `bes` | `bundle exec rails s` |
| `j` / `z` | `zoxide z <dir>` (smart cd) |

## Customization

- **Prompt**: edit `.config/starship.toml`
- **Aliases**: add to the Aliases section in `.zshrc`
- **Plugins**: add clone commands to `install.sh` and source lines to `.zshrc`
