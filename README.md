# dotfiles

Personal dev environment — zsh, oh-my-zsh, Powerlevel10k, Ghostty, and herdr.
This README is a guidemap, not a one-click installer: install the tools you
need from the table below, then run the bootstrap to put the configs in place.

## Quick start

```sh
git clone https://github.com/HammadTheOne/dotfiles
cd dotfiles
./bootstrap/install.sh
exec zsh
```

The installer sets up oh-my-zsh, the custom plugins (`zsh-autosuggestions`,
`zsh-syntax-highlighting`, `zsh-history-substring-search`), and Powerlevel10k,
then copies the tracked configs into place (backing up anything that exists).
It's idempotent — safe to re-run.

| Config | Installed to |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.p10k.zsh` | `~/.p10k.zsh` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |

> Requires `git`, `curl`, and `zsh` — all present on a stock Mac.

## Tools

| Tool | What it's for | Install |
|---|---|---|
| [Ghostty](https://ghostty.org) | Terminal emulator (GPU-rendered, truecolor) | `brew install --cask ghostty` |
| [herdr](https://herdr.dev) | Terminal workspace manager / multiplexer — persistent panes, tabs, socket API | `brew install herdr` |
| [Task](https://taskfile.dev) | Task runner (numbox's `task start`, etc.) | `brew install go-task/tap/go-task` |
| [uv](https://docs.astral.sh/uv/) | Python package & project manager | `brew install uv` |
| [Redis](https://redis.io) | Local Celery broker | `brew install redis` |
| [PostgreSQL 16](https://www.postgresql.org) | Local database | `brew install postgresql@16` |
| [ngrok](https://ngrok.com) | Tunnels for Twilio / webhook development | `brew install --cask ngrok` |
| [jq](https://jqlang.github.io/jq/) | JSON parsing in dev scripts (`herd-dev.sh`) | `brew install jq` |

## Numbox dev stack

The numbox dev stack has its own one-time setup — DB cluster (`initdb`,
`createuser`, `createdb`), ngrok auth (`task configure-ngrok`), Twilio numbers,
`.env` — documented in the numbox repo's [`docs/LOCAL_ENV_SETUP.md`](https://github.com/NumberAI/numbox/blob/master/docs/LOCAL_ENV_SETUP.md).

Day to day, `numboxup` (aliased in `.zshrc`, backed by
`scripts/herd-dev.sh`) drives herdr to spin up the whole stack in one shot: a
workspace with named tabs for Flask, Celery (worker + beat), and Services
(redis / ngrok / postgres), cleaning up strays from previous runs first. Start
`herdr`, run `numboxup` in any pane. It targets the numbox checkout at
`$NUMBOX_DIR` (default `~/Documents/numbox`).

## Alternates

- `AdventureTime.terminal` — Apple Terminal color profile (double-click to
  import, then set as default) if you're not using Ghostty.
- `ghostty/config.adventuretime` — the same AdventureTime palette ported to
  Ghostty; swap it in over `~/.config/ghostty/config` if you prefer it to
  TokyoNight Night.
