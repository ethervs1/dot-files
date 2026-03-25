#!/bin/bash
set -euo pipefail

# =============================================================================
# macOS Fresh Setup Script (Sonoma or later, Apple Silicon)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname -- "$0")" && pwd)"

# -----------------------------------------------------------------------------
# 1. Create Git and Temp Directories and Symlinks
# -----------------------------------------------------------------------------
echo "Creating git and temp directories in Documents and symlinks in home..."
mkdir -p ~/Documents/git ~/Documents/temp
ln -sfn ~/Documents/git ~/git
ln -sfn ~/Documents/temp ~/temp

# -----------------------------------------------------------------------------
# 2. Install Xcode Command Line Tools
# -----------------------------------------------------------------------------
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Waiting for Xcode Command Line Tools installation..."
  echo "Press any key once the installation GUI has completed."
  read -r -n 1
fi
echo "Xcode CLT installed at: $(xcode-select -p)"

# -----------------------------------------------------------------------------
# 3. Install Homebrew
# -----------------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
else
  echo "Homebrew already installed."
fi

# -----------------------------------------------------------------------------
# 4. Install Homebrew Apps from Brewfile
# -----------------------------------------------------------------------------
echo "Installing apps from Brewfile..."
brew bundle --file="$SCRIPT_DIR/homebrew/Brewfile"

# -----------------------------------------------------------------------------
# 5. Install Oh My Zsh
# -----------------------------------------------------------------------------
if [[ ! -d ~/.oh-my-zsh ]]; then
  echo "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed."
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# -----------------------------------------------------------------------------
# 6. Install Powerlevel10k
# -----------------------------------------------------------------------------
echo "Installing Powerlevel10k..."
brew install powerlevel10k
echo 'source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

# -----------------------------------------------------------------------------
# 7. Install zsh-autocomplete
# -----------------------------------------------------------------------------
echo "Installing zsh-autocomplete..."
brew install zsh-autocomplete
echo 'source $HOMEBREW_PREFIX/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh' >> ~/.zshrc

# -----------------------------------------------------------------------------
# 8. Install zsh-autosuggestions
# -----------------------------------------------------------------------------
echo "Installing zsh-autosuggestions..."
brew install zsh-autosuggestions
echo 'source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc

# -----------------------------------------------------------------------------
# 9. Source Custom Init
# -----------------------------------------------------------------------------
echo "Adding custom init to .zshrc..."
echo 'source ~/git/machine_setup/init.zsh' >> ~/.zshrc

# -----------------------------------------------------------------------------
# 10. Create ~/.ssh/config for 1Password SSH
# -----------------------------------------------------------------------------
echo "Configuring SSH for 1Password agent..."
mkdir -p ~/.ssh
cat > ~/.ssh/config << 'EOF'
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
chmod 600 ~/.ssh/config

# -----------------------------------------------------------------------------
# 11. Final Cleanup and Checks
# -----------------------------------------------------------------------------
echo "Running Homebrew maintenance..."
brew update && brew upgrade && brew cleanup && brew autoremove && brew doctor

echo "Running mole cleanup..."
mo clean
mo optimize

echo ""
echo "=== Setup complete! ==="
echo "Open a new terminal (or run source ~/.zshrc manually) and run: p10k configure"
