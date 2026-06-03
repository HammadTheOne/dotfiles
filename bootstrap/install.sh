#!/usr/bin/env bash
#
# Bootstrap the zsh environment on a fresh machine:
#   1. oh-my-zsh
#   2. custom plugins (zsh-autosuggestions, zsh-syntax-highlighting,
#      zsh-history-substring-search) — these are NOT tracked in this repo
#   3. powerlevel10k theme
#   4. install the tracked dotfiles (.zshrc, .p10k.zsh), backing up any existing
#
# Idempotent and safe to re-run. Usage:  ./bootstrap/install.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# 1. oh-my-zsh
if [ ! -d "$ZSH" ]; then
	echo "==> Installing oh-my-zsh"
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	echo "==> oh-my-zsh already present"
fi

# 2 & 3. clone (or update) third-party plugins and the theme
clone_or_update() {
	local url="$1" dest="$2"
	if [ -d "$dest/.git" ]; then
		echo "==> Updating $(basename "$dest")"
		git -C "$dest" pull --ff-only --quiet || true
	else
		echo "==> Cloning $(basename "$dest")"
		git clone --depth=1 "$url" "$dest"
	fi
}

clone_or_update https://github.com/zsh-users/zsh-autosuggestions         "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
clone_or_update https://github.com/romkatv/powerlevel10k                  "$ZSH_CUSTOM/themes/powerlevel10k"

# 4. install tracked dotfiles, backing up any pre-existing copies
stamp="$(date +%Y%m%d_%H%M%S)"
install_file() {
	local src="$1" dest="$2"
	if [ -e "$dest" ] && ! [ "$dest" -ef "$src" ]; then
		cp "$dest" "$dest.backup.$stamp"
		echo "==> Backed up $dest -> $dest.backup.$stamp"
	fi
	cp "$src" "$dest"
	echo "==> Installed $dest"
}

install_file "$DOTFILES_DIR/.zshrc"    "$HOME/.zshrc"
install_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"

echo
echo "Done. Start a fresh shell with:  exec zsh"
