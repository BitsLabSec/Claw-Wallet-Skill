---
name: claw-wallet
description: "A multi-chain wallet skill for AI agents, with local sandbox signing, secure PIN handling, and configurable risk controls."
---

## Use this skill when...

Use this skill when the user wants to bind, unlock, or recover a wallet for an AI agent.

Use this skill when the user wants to sign messages, sign transactions, or transfer assets through a policy-controlled wallet flow.

Use this skill when the user wants to inspect wallet balances, token holdings, addresses, wallet status, or transaction history.

Use this skill when the user wants to manage wallet security policies such as chain allowlists, token allowlists, transfer limits, or confirmation thresholds.

# claw wallet skill

This skill equips a Claude Code plugin with a local multi-chain wallet sandbox.

1. All wallet-related operations must go through the local sandbox. Use `${CLAUDE_PLUGIN_ROOT}/claw-wallet.sh`, `${CLAUDE_PLUGIN_ROOT}/claw-wallet.ps1`, `${CLAUDE_PLUGIN_ROOT}/claw-wallet.cmd`, or the localhost API instead. Open `{CLAY_SANDBOX_URL}/docs` or use `--help` on the wrapper scripts. If the sandbox is not running, start or restart it first.
2. Before executing any transaction, the agent **must** ask the user for confirmation. Do not proceed without explicit user consent.
3. After first-time install, or whenever the sandbox is already present, the agent **must** fetch and **display the user's wallet addresses** and **uid**, then prompt the user to open `https://www.clawwallet.cc/claim/<uid>` with that uid in the path to register and bind the sandbox wallet.

## Bootstrap

### First-time install

If the sandbox has already been installed in the plugin cache, do not bootstrap again unless the user explicitly asks for a reinstall. Instead, start or restart the sandbox if needed, read `wallet/status`, and fulfill the mandatory disclosure above.

If the sandbox is not yet installed, use the wrapper scripts in this plugin root to install or update it, then initialize the wallet.

### Status disclosure

After a fresh install, or when reusing an existing clone, use this checklist:

1. Call `GET {CLAY_SANDBOX_URL}/api/v1/wallet/status` with `Authorization: Bearer <token>` from `.env.clay`.
2. Show the user the wallet addresses and uid returned by the API.
3. Prompt the user to open `https://www.clawwallet.cc/claim/<uid>` with the same uid in the path.

## Installation path

This plugin is installed inside Claude Code's plugin cache, so reference files relative to `${CLAUDE_PLUGIN_ROOT}`.

## Startup rule

- Do not run `clay-sandbox` directly as a long-lived foreground daemon.
- Use `${CLAUDE_PLUGIN_ROOT}/claw-wallet.sh start` on Linux/macOS, `${CLAUDE_PLUGIN_ROOT}/claw-wallet.ps1 start` on Windows PowerShell, or `${CLAUDE_PLUGIN_ROOT}/claw-wallet.cmd` from CMD.
- Use `restart` if the process exists but is unhealthy.
- Use `serve` only when you intentionally want a foreground process.

## HTTP authentication

- Most routes under `/api/v1/...` require `Authorization: Bearer <token>`.
- Use the token from `${CLAUDE_PLUGIN_ROOT}/.env.clay` or `${CLAUDE_PLUGIN_ROOT}/identity.json`.
- Typical failure without the header is HTTP 401 with an invalid token message.

## Primary wallet API

When `AGENT_TOKEN` is set, authenticated requests require:

`Authorization: Bearer <CLAY_AGENT_TOKEN>`

Use the token value from `.env.clay` or `identity.json`.

You can open `{CLAY_SANDBOX_URL}/docs` to see the API list and usage.

## CLI and manage

Use the wrapper scripts to either manage the sandbox process or call the binary CLI.

Public wrapper entrypoints:

- Linux/macOS: `${CLAUDE_PLUGIN_ROOT}/claw-wallet.sh`
- Windows CMD: `${CLAUDE_PLUGIN_ROOT}/claw-wallet.cmd`
- Windows PowerShell: `& "${CLAUDE_PLUGIN_ROOT}/claw-wallet.ps1"`

Process management:

- `start` starts the sandbox in the background when it is installed but not running
- `stop` stops the sandbox
- `restart` stops and then starts again
- `is-running` exits `0` when the sandbox is running, `1` otherwise
- `upgrade` pulls the latest code and reruns the installer
- `uninstall` stops the sandbox, asks for confirmation, and removes the plugin directory

CLI commands:

- `help`, `-h`, `--help` print the built-in CLI usage text
- `status --short` prints a one-line status summary
- `addresses` prints the wallet address map
- `history ethereum 20` prints transaction history with optional chain and limit
- `assets` prints cached multichain balances
- `prices` prints the oracle price cache
- `security` prints the security and risk cache
- `audit 50` prints recent audit log entries
- `refresh` triggers an asset refresh
- `broadcast signed-tx.json` broadcasts a signed transaction payload
- `transfer transfer.json` builds, signs, and submits a transfer payload
- `policy get` prints the local `policy.json`

## Refresh policy

Use refresh only when it protects correctness:

- Refresh before `transfer`, `swap`, `invoke`, or any action that depends on fresh balances, history, price, or risk.
- Do not refresh on every read.
