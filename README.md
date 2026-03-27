# Claw Wallet Skill

Local sandbox wallet skill for OpenClaw agents. Install the sandbox locally, operate through localhost APIs or CLI, and support both local wallets and phase2 remote-managed wallets.

## Installation

### Option 1: Git clone (recommended)

```bash
mkdir -p skills
git clone https://github.com/ClawWallet/Claw-Wallet-Skill.git skills/claw-wallet
bash skills/claw-wallet/install.sh
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Path "skills" -Force | Out-Null
git clone https://github.com/ClawWallet/Claw-Wallet-Skill.git "skills/claw-wallet"
& "skills/claw-wallet/install.ps1"
```

### Option 2: npx skills add

```bash
npx skills add ClawWallet/Claw-Wallet-Skill -a openclaw --yes
```

This installs the skill into your workspace `skills/` directory. Then run the installer:

```bash
bash skills/claw-wallet/install.sh
```

Windows PowerShell:

```powershell
& "skills/claw-wallet/install.ps1"
```
## After install

Verify status:

- `GET {CLAY_SANDBOX_URL}/health` — expected: `{"status": "ok"}`
- `GET {CLAY_SANDBOX_URL}/api/v1/wallet/status` with `Authorization: Bearer <token>` — confirm wallet is ready

Token and URL are in `skills/claw-wallet/.env.clay`.

## Documentation

See [SKILL.md](./SKILL.md) for full documentation, API reference, and agent rules.
