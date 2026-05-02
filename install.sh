#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# nikky-cmd — Portable zsh environment installer
# =============================================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh"

# Behavior toggles (can be overridden via environment)
# Set NONINTERACTIVE=1 for CI/non-interactive installs
NONINTERACTIVE=${NONINTERACTIVE:-0}
# Set NO_AUTO_UPDATE=1 to skip updating plugins during install
NO_AUTO_UPDATE=${NO_AUTO_UPDATE:-0}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

# Prompt helper: returns 0 for yes, 1 for no. Respects NONINTERACTIVE.
confirm() {
  if [[ "${NONINTERACTIVE}" -eq 1 ]]; then
    return 0
  fi
  local prompt="${1:-Proceed? (y/N)}"
  read -r -p "$prompt " ans
  case "$ans" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

# Detect package manager
detect_pkg_manager() {
  if command -v brew &>/dev/null; then
    PKG_MANAGER="brew"
  elif command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt"
  else
    warn "No supported package manager found (brew/apt). Install dependencies manually."
    PKG_MANAGER="none"
  fi
}

# Install a package if not present (prompts by default)
install_if_missing() {
  local cmd="$1" pkg="$2"
  if command -v "$cmd" &>/dev/null; then
    info "$cmd already installed"
    return 0
  fi
  info "About to install $pkg (provides $cmd)"
  if ! confirm "Install $pkg now? (requires $PKG_MANAGER) [y/N]"; then
    warn "Skipping install of $pkg"
    return 1
  fi
  case "$PKG_MANAGER" in
    brew) brew install "$pkg" ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y "$pkg"
      ;;
    *)
      warn "Cannot install $pkg — no package manager available"
      return 1
      ;;
  esac
}

# Clone a git repo if not present. Usage: clone_plugin <repo> <dest> [ref]
clone_plugin() {
  local repo="$1" dest="$2" ref="${3:-}"
  if [[ -d "$dest" ]]; then
    info "Plugin already exists: $dest"
    if [[ -d "$dest/.git" ]]; then
      (cd "$dest" && printf "  current: %s\n" "$(git rev-parse --short HEAD)") || true
    fi
    return 0
  fi
  info "Cloning $repo → $dest"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$repo" "$dest"
  else
    git clone --depth 1 "$repo" "$dest"
  fi
  if [[ -d "$dest/.git" ]]; then
    (cd "$dest" && printf "  cloned: %s\n" "$(git rev-parse --short HEAD)") || true
  fi
}

# Create symlink, backing up existing file if needed (asks before overwriting)
link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    local target
    target=$(readlink "$dst") || target=""
    if [[ "$target" == "$src" ]]; then
      info "Symlink already exists: $dst"
      return 0
    fi
    if ! confirm "Existing symlink $dst points to $target — replace? [y/N]"; then
      warn "Skipping symlink update for $dst"
      return 1
    fi
    rm -f "$dst"
  fi
  if [[ -e "$dst" ]]; then
    if ! confirm "File exists at $dst — back up and replace? [y/N]"; then
      warn "Skipping link for $dst"
      return 1
    fi
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    warn "Backing up $dst → $backup"
    mv "$dst" "$backup"
  fi
  ln -sf "$src" "$dst"
  info "Linked $dst → $src"
}

# =============================================================================
# Main
# =============================================================================

echo ""
echo "  nikky-cmd — Portable zsh environment"
echo ""

# Step 1: Ensure zsh is installed
if ! command -v zsh &>/dev/null; then
  info "zsh not found, installing..."
  detect_pkg_manager
  case "$PKG_MANAGER" in
    brew) brew install zsh ;;
    apt) sudo apt-get update && sudo apt-get install -y zsh ;;
    *) error "zsh not found and no package manager available"; exit 1 ;;
  esac
  info "zsh installed: $(command -v zsh)"
fi

# Step 2: Detect package manager for dependency installation
detect_pkg_manager
info "Package manager: $PKG_MANAGER"

# Step 3: Install dependencies
echo ""
info "Checking dependencies..."
install_if_missing rg ripgrep
install_if_missing fzf fzf
install_if_missing zoxide zoxide
install_if_missing starship starship
install_if_missing vim vim

# Step 3b: Install rbenv
echo ""
info "Checking rbenv..."
if ! command -v rbenv &>/dev/null; then
  info "Installing rbenv..."
  case "$PKG_MANAGER" in
    brew)
      brew install rbenv ruby-build
      ;;
    apt)
      sudo apt-get update
      sudo apt-get install -y git curl autoconf build-essential libssl-dev \
        libyaml-dev libreadline-dev zlib1g-dev libffi-dev libgdbm-dev
      git clone --depth 1 https://github.com/rbenv/rbenv.git ~/.rbenv
      git clone --depth 1 https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
      echo ""
      export PATH="$HOME/.rbenv/bin:$PATH"
      # Add rbenv to PATH persistently
      if ! grep -q 'rbenv/bin' "$HOME/.zshrc" 2>/dev/null; then
        echo '' >> "$HOME/.zshrc"
        echo '# rbenv' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.zshrc"
        echo 'eval "$(rbenv init - zsh)"' >> "$HOME/.zshrc"
        info "Added rbenv to ~/.zshrc"
      fi
      if confirm "Initialize rbenv in the current shell session now? [y/N]"; then
        eval "$(rbenv init -)"
        info "rbenv initialized in current session"
      else
        info "rbenv will be available in new shell sessions"
      fi
      ;;
    *)
      warn "Cannot install rbenv — no package manager available"
      ;;
  esac
else
  info "rbenv already installed"
  # Ensure ruby-build is present (macOS via brew)
  if [[ "$PKG_MANAGER" == "brew" ]] && ! brew list ruby-build &>/dev/null; then
    info "Installing ruby-build..."
    brew install ruby-build
  fi
  # Add rbenv to PATH for subsequent ruby installs
  export PATH="$HOME/.rbenv/bin:$PATH"
  if confirm "Initialize rbenv in the current shell session now? [y/N]"; then
    eval "$(rbenv init -)"
    info "rbenv initialized in current session"
  else
    warn "Skipping immediate rbenv init. Add 'eval "$(rbenv init -)"' to your shell rc to enable rbenv."
  fi
fi

# Step 4: Install plugins
echo ""
info "Installing plugins to $ZSH_PLUGINS_DIR..."
mkdir -p "$ZSH_PLUGINS_DIR"

clone_plugin \
  "https://github.com/zsh-users/zsh-autosuggestions" \
  "$ZSH_PLUGINS_DIR/zsh-autosuggestions"

clone_plugin \
  "https://github.com/zsh-users/zsh-syntax-highlighting" \
  "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"



# Step 5: Create directories and symlink config files
echo ""
info "Setting up configuration..."

mkdir -p "$HOME/.config"

link_file "$REPO_DIR/.zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Step 6: Set zsh as default shell (optional, non-interactive)
echo ""
if [[ "$SHELL" != *"zsh"* ]]; then
  warn "Your default shell is not zsh."
  echo "  To set zsh as default, run: chsh -s $(command -v zsh)"
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "  On macOS, you may need to: Settings → Users → Advanced → Change shell"
  fi
else
  info "zsh is already your default shell"
fi

# Step 7: Update plugins (if they already existed)
echo ""
if [[ "${NO_AUTO_UPDATE}" -eq 1 ]]; then
  info "Skipping plugin auto-update (NO_AUTO_UPDATE=1)"
else
  for dir in "$ZSH_PLUGINS_DIR"/*/; do
    if [[ -d "$dir/.git" ]]; then
      info "Updating plugin: $dir"
      (cd "$dir" && git pull --ff-only) || warn "Failed to update plugin: $dir"
      (cd "$dir" && printf "  now at %s\n" "$(git rev-parse --short HEAD)") || true
    fi
  done
  info "Plugins updated"
fi

echo ""
echo "  Done! Start a new zsh session to use the new configuration."
echo "  Run: exec zsh"
echo ""
