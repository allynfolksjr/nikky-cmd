#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# nikky-cmd — Portable zsh environment installer
# =============================================================================

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZSH_PLUGINS_DIR="$HOME/.local/share/zsh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

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

# Install a package if not present
install_if_missing() {
  local cmd="$1" pkg="$2"
  if command -v "$cmd" &>/dev/null; then
    info "$cmd already installed"
    return
  fi
  info "Installing $pkg..."
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

# Clone a git repo if not present
clone_plugin() {
  local repo="$1" dest="$2"
  if [[ -d "$dest" ]]; then
    info "Plugin already exists: $dest"
    return
  fi
  info "Cloning $repo → $dest"
  git clone --depth 1 "$repo" "$dest"
}

# Create symlink, backing up existing file if needed
link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    info "Symlink already exists: $dst"
    return
  fi
  if [[ -e "$dst" ]]; then
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
install_if_missing fzf fzf
install_if_missing zoxide zoxide
install_if_missing starship starship

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
      eval "$(rbenv init -)"
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
  eval "$(rbenv init -)"
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

clone_plugin \
  "https://github.com/Aloxaf/fzf-tab" \
  "$ZSH_PLUGINS_DIR/fzf-tab"

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
for dir in "$ZSH_PLUGINS_DIR"/*/; do
  if [[ -d "$dir/.git" ]]; then
    (cd "$dir" && git pull --ff-only &>/dev/null || true) &
  fi
done
wait
info "Plugins updated"

echo ""
echo "  Done! Start a new zsh session to use the new configuration."
echo "  Run: exec zsh"
echo ""
