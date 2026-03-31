# Claw Wallet Skill

Local sandbox wallet skill for OpenClaw and Claude Code agents. Install the sandbox locally, operate through localhost APIs or CLI, and support both local wallets and phase2 remote-managed wallets.

This `README` targets the `dev` test environment. The installer and upgrade flow pull skill code from [`Claw-Wallet-Skill`](https://github.com/ClawWallet/Claw-Wallet-Skill/tree/dev) `dev` and sandbox binaries from [`Claw_Wallet_Bin`](https://github.com/ClawWallet/Claw_Wallet_Bin/tree/dev) `dev`.

## Claude Code marketplace

This repository is now structured so it can be added as a third-party Claude Code marketplace.

Use:

```bash
/plugin marketplace add <this-repo-url>
/plugin install claw-wallet@claw-wallet-marketplace
```

This is a community marketplace setup, not an Anthropic-curated listing. To appear in Anthropic's official directory, the repo still needs to pass their review and submission flow.

## Installation

### Option 1: Git clone (recommended)

```bash
mkdir -p skills
git clone --branch dev https://github.com/ClawWallet/Claw-Wallet-Skill.git skills/claw-wallet-dev
bash skills/claw-wallet-dev/install.sh
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Path "skills" -Force | Out-Null
git clone --branch dev https://github.com/ClawWallet/Claw-Wallet-Skill.git "skills/claw-wallet-dev"
& "skills/claw-wallet-dev/install.ps1"
```

### Option 2: npx skills add

For the `dev` test environment, prefer Option 1 so the local checkout is pinned to the `dev` branch explicitly.

```bash
npx skills add ClawWallet/Claw-Wallet-Skill -a openclaw --yes
```

This installs the skill into your workspace `skills/` directory. Then run the installer:

```bash
bash skills/claw-wallet-dev/install.sh
```

Windows PowerShell:

```powershell
& "skills/claw-wallet-dev/install.ps1"
```
## After install

Verify status:

- `GET {CLAY_SANDBOX_URL}/health` — expected: `{"status": "ok"}`
- `GET {CLAY_SANDBOX_URL}/api/v1/wallet/status` with `Authorization: Bearer <token>` — confirm wallet is ready

Token and URL are in `skills/claw-wallet-dev/.env.clay`.

## Documentation

See [SKILL.md](./SKILL.md) for full documentation, API reference, and agent rules.
