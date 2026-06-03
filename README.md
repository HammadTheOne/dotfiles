# dotfiles

Personal dotfiles for zsh, oh-my-zsh, and Powerlevel10k.

## Contents
- `.zshrc` — zsh / oh-my-zsh config
- `.p10k.zsh` — Powerlevel10k prompt (nerdfont-v3)
- `AdventureTime.terminal` — macOS Terminal color profile
- `bootstrap/install.sh` — fresh-machine setup

## Setup on a new machine
```sh
git clone https://github.com/HammadTheOne/dotfiles
cd dotfiles
./bootstrap/install.sh
exec zsh
```

The installer sets up oh-my-zsh, the custom plugins (`zsh-autosuggestions`,
`zsh-syntax-highlighting`, `zsh-history-substring-search`), and Powerlevel10k,
then installs `.zshrc` and `.p10k.zsh` (backing up any existing copies). It's
idempotent — safe to re-run.

> Requires `git`, `curl`, and `zsh` to already be installed.
