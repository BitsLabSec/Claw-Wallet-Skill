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

This skill equips an OpenClaw agent with a local multi-chain wallet sandbox.

1. All wallet-related operations must go through the local sandbox. Use the localhost API or sandbox CLI instead. Open `{CLAY_SANDBOX_URL}/docs` or use --help command. If sandbox is not running, start/restart it first.
2. Before executing any transaction, the agent **must** ask the user for confirmation (e.g. "Confirm to execute this transaction?"). Do not proceed without explicit user consent.
3. After first-time install, the agent **must** fetch and **display the user's wallet addresses**, **uid**. **Prompt** the user to open `https://www.clawwallet.cc/claim/<uid>` **with that uid in the path** (substitute `<uid>`) to register and bind the sandbox wallet.

## Bootstrap

### First-time install

**Before cloning or running the installer:** From the **workspace root**, check whether **`skills/claw-wallet`** already exists (same path as in **Installation path** below).

- **If it exists:** Do **not** run the git clone or `install.sh` / `install.ps1` bootstrap unless the user explicitly wants a reinstall. Ensure the sandbox is running (`skills/claw-wallet/claw-wallet.sh start` on Linux/macOS, `skills/claw-wallet/claw-wallet.ps1 start` on Windows; use `restart` if unhealthy). Then call `GET {CLAY_SANDBOX_URL}/api/v1/wallet/status` with `Authorization: Bearer <token>` from **.env.clay** and fulfill **rule 3** (addresses, **uid**, prompt to `https://www.clawwallet.cc/claim/<uid>` with uid in the path) using the **Status disclosure** checklist below. **Stop here** — no bootstrap.
- **If it does not exist:** Continue with **Bootstrap (new clone)** below.

#### Bootstrap (new clone)

Clone this repo into `skills/claw-wallet` under your workspace and run the installer. The installer automatically initializes the wallet. 

Linux/macOS:

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

#### Status disclosure (after bootstrap **or** when reusing an existing clone)

Use this checklist whenever the user needs the mandatory disclosure (rule 3): after a **fresh install**, or when **`skills/claw-wallet/`** was already present and you started the sandbox without cloning.

1. `GET {CLAY_SANDBOX_URL}/api/v1/wallet/status` with `Authorization: Bearer <token>` — confirm wallet is ready. The response includes **address information** and **uid** (when present). **You must show the user:** **wallet addresses** (from the response), **uid** (from the response when present) ( HTTP API under `/api/v1/…`, Swagger at `/docs`, same origin).  read it only from `.env.clay` / `identity.json` for `Authorization` (see **HTTP authentication (sandbox)** below).
2. **Prompt the user:** To fully control your wallet with a better experience, open `https://www.clawwallet.cc/claim/<uid>` **with the same uid in the path** (replace `<uid>` with the uid from step 1) to register and bind your sandbox wallet.

## Installation path

All files live in one directory:

```
{your_workspace}/skills/claw-wallet/
```

| Platform | Resolved path |
|----------|---------------|
| Linux/macOS | `skills/claw-wallet/` (relative to workspace root) |
| Windows | `skills\claw-wallet\` (relative to workspace root) |

## Startup rule:

- do not run `clay-sandbox` directly as a long-lived foreground daemon from OpenClaw
- use `skills/claw-wallet/claw-wallet.sh start` / `skills/claw-wallet/claw-wallet.ps1 start`
- use `restart` if the process exists but is unhealthy
- use `serve` only when you intentionally want a foreground process

Don't forget to hint user: To gain fully control your wallet by user with a better experience, open `https://www.clawwallet.cc/claim/<uid>` **with that uid in the path** to register and bind the sandbox wallet.

### Register and bind (website vs agent)

**End users (browser):** Open `https://www.clawwallet.cc/claim/<uid>` in the browser, substituting `<uid>` with the wallet **uid** from `wallet/status`, to start the bind flow; the `/claim/…` path **must** include that uid (see [Claw Wallet](https://www.clawwallet.cc/)).

**Agents (automating bind after the user starts the flow):** The user will obtain a **`message_hash_hex`** from the Claw bind / challenge step and paste or send it to you. You must call the **sandbox** bind API with the same bearer token used for all authenticated sandbox requests.

1. **Token:** Use **`AGENT_TOKEN`** / **`CLAY_AGENT_TOKEN`** from `skills/claw-wallet/.env.clay` (or `agent_token` in `identity.json`). Send it as:
   - `Authorization: Bearer <token>`
2. **Request:**
   - **Method:** `POST`
   - **URL:** `{CLAY_SANDBOX_URL}/api/v1/wallet/bind`
   - **Headers:** `Content-Type: application/json`, plus `Authorization` above
   - **Body (JSON):** `{ "message_hash_hex": "<value from user>" }`
3. **Behavior:** The sandbox signs locally and forwards the result to the relay

**Example (bash / Linux / macOS):** `curl` is usually available.

```bash
curl -sS -X POST "${CLAY_SANDBOX_URL}/api/v1/wallet/bind" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${AGENT_TOKEN}" \
  -d "{\"message_hash_hex\":\"<hex from user>\"}"
```

**Windows:** A plain **CMD** window may not have `curl` on older systems, or agents may run only **PowerShell**. Prefer one of:

- **PowerShell 7+ / Windows Terminal** often ships with **`curl.exe`** (real curl). If `curl --version` works, the bash example above is fine (use `$env:CLAY_SANDBOX_URL` / `$env:AGENT_TOKEN` or substitute literals).
- If `curl` is missing or fails, use **`Invoke-RestMethod`** (built in):

```powershell
$body = @{ message_hash_hex = "<hex from user>" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$env:CLAY_SANDBOX_URL/api/v1/wallet/bind" `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $env:AGENT_TOKEN" } `
  -Body $body
```

### Health check

After install or relaunch, verify:

- `GET {CLAY_SANDBOX_URL}/health`
- expected response: `{"status":"ok"}`

## HTTP authentication (sandbox)

- **Most** routes under `/api/v1/…` (wallet status, sign, transfer, etc.) require:
  - `Authorization: Bearer <token>`
  - where `<token>` is **exactly** the same value as `AGENT_TOKEN` / `CLAY_AGENT_TOKEN`.
- **Typical failure without the header:** HTTP **401** with body `Unauthorized: invalid claw wallet sandbox token`.

### Where to read the token (same secret, duplicated for convenience)

| Location | Field(s) |
|----------|-----------|
| `skills/claw-wallet/.env.clay` | **`CLAY_SANDBOX_URL`** — base URL (scheme, host, port) for the sandbox HTTP server (API `/api/v1/…`, `/docs`). Also `CLAY_AGENT_TOKEN` or `AGENT_TOKEN` (same value; installer/bootstrap writes both). |
| `skills/claw-wallet/identity.json` | `agent_token` |

Example workspace test layout (same idea):

- `wallet_test/<sim>/.env.clay`
- `wallet_test/<sim>/identity.json`

### Swagger UI (`/docs`)

We have a list of sandbox API at `{CLAY_SANDBOX_URL}/docs`,

### Unauthenticated or special paths (examples)

- `GET /health` — no bearer required
- `GET /docs`, `GET /openapi.yaml` — no bearer (documentation only)
- Exact list is defined by the sandbox binary; see `/openapi.yaml` on a running sandbox

## Primary wallet API

When `AGENT_TOKEN` is set, authenticated requests require:

`Authorization: Bearer <CLAY_AGENT_TOKEN>`

Use the token value from `.env.clay` or `identity.json` as described in **HTTP authentication (sandbox)** above.

You can Open `{CLAY_SANDBOX_URL}/docs` to see the list of our API and how to use.

## Upgrade and Uninstall

### Upgrade

- **If installed via git clone:** `git stash` → `git pull` → `git stash pop`, then rerun the installer. Local changes are preserved.
- **If installed via npx skills add (no `.git`):** Backs up `.env.clay`/`identity.json`/`share3.json` to a temp dir, then `git init` → `git fetch` → `git reset --hard origin/main` → restore from temp → rerun installer. After the first upgrade, `.git` exists so future upgrades use the normal git flow.

Wallet data (`.env.clay`, `identity.json`, `share3.json`) is preserved in both cases.

Linux/macOS:

```bash
skills/claw-wallet/claw-wallet.sh upgrade
```

Windows PowerShell:

```powershell
& "skills/claw-wallet/claw-wallet.ps1" upgrade
```

### Uninstall

**If you are an agent:**
1. You **must** ask the user for permission before executing the uninstall command. Do not run it automatically.
2. You **must** inform the user: *"Before uninstalling, you must backup `.env.clay`, `identity.json`, and `share3.json` if you need to recover the wallet later. Deletion is irreversible."*
3. Proceed only after the user has explicitly confirmed.

**If you are a user:** Before uninstalling, you must backup `.env.clay`, `identity.json`, and `share3.json` if you need to recover the wallet later. Deletion is irreversible.

The uninstall script will:
1. Stop the sandbox process
2. Display a warning and ask for confirmation
3. Proceed only if you type `yes`
4. Remove the entire skill directory

Linux/macOS:

```bash
bash skills/claw-wallet/claw-wallet.sh uninstall
```

Windows PowerShell:

```powershell
& "skills/claw-wallet/claw-wallet.ps1" uninstall
```

## CLI and Manage

Use the wrapper scripts to either manage the sandbox process or call the binary CLI.

Public wrapper entrypoints:

- Linux/macOS: `skills/claw-wallet/claw-wallet.sh`
- Windows CMD: `skills\claw-wallet\claw-wallet.cmd`
- Windows PowerShell: `& "skills/claw-wallet/claw-wallet.ps1"`

Process management:

- `start` starts the sandbox in the background when it is installed but not running
- `stop` stops the sandbox
- `restart` stops and then starts again
- `is-running` exits `0` when the sandbox is running, `1` otherwise
- `upgrade` pulls the latest code (git or npx skills update) and reruns the installer
- `uninstall` stops the sandbox, asks for confirmation, and removes the skill directory

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
- `policy get` prints the local `policy.json` via **`GET /api/v1/policy/local`** (read-only). The merged policy view also appears on **`GET /api/v1/wallet/status`** under `policy`.
- Policy **cannot** be changed from the sandbox CLI or a generic sandbox POST API. After the wallet is bound, users adjust limits and rules in the **Claw app**; the relay may also **push** policy updates to the sandbox (file on disk).

Windows equivalents use the same subcommands through `claw-wallet.ps1`, for example:

- `& "skills/claw-wallet/claw-wallet.ps1" help`
- `& "skills/claw-wallet/claw-wallet.ps1" status --short`
- `Get-Content policy.json | & "skills/claw-wallet/claw-wallet.ps1" policy set -`

Help and usage:

- `help`, `-h`, and `--help` are equivalent for the sandbox binary
- These flags print the built-in CLI usage text from the binary itself, not a wrapper-specific summary
- The help output is grouped by area: server, wallet read commands, policy, transaction helpers, and local bootstrap / utility commands
- Running the binary with no subcommand starts the HTTP server, so use `help` explicitly when you want usage text instead of a foreground daemon


## Refresh policy

Use refresh only when it protects correctness:

- Must refresh before `transfer`, `swap`, `invoke`, or any action that depends on fresh balances, history, price, or risk.
- The sandbox already refreshes automatically in the corresponding managed execution paths when it needs to.
- For manual refresh, use the sandbox `refresh` CLI command (or the refresh API if exposed).
- For OpenClaw / agent automation, call the sandbox refresh API explicitly before transaction execution when the cached state may be stale.
- Do not refresh on every read. Assets/history views should stay cache-first unless the cache is stale or the user explicitly requests a refresh.