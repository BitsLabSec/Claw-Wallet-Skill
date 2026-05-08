---
name: claw-wallet-bridge
description: "Cross-chain bridge skill for AI agents using LI.FI, enabling seamless asset transfers between 20+ chains including EVM, Solana, and Sui."
short_description: "Multi-chain asset bridge using LI.FI."
default_prompt: "Use $skill-name to quote and execute cross-chain asset transfers between different networks like Ethereum, BSC, Solana, and Sui."
---

## Use this skill when...

Use this skill when the user wants to transfer tokens from one blockchain to another (e.g., from Ethereum to Solana, or BSC to Sui).

Use this skill when the user wants to estimate the cost, time, and received amount for a cross-chain swap.

Use this skill when the user needs to find the exact contract address of a token on a specific chain before bridging.

# bridge skill

This skill provides a managed cross-chain bridge experience powered by LI.FI, integrated directly with the local wallet sandbox for secure signing.

## Core Flow

To ensure a successful bridge, the agent **MUST** follow these steps:

1. **Verify Token Support**: Call `/api/v1/tx/bridge/lifi/tokens` to get the correct contract address for the source and target chains.
2. **Get Quote**: Call `/api/v1/tx/bridge/lifi/quote` to show the user the estimated received amount, fees, and duration.
3. **User Confirmation**: Present the quote to the user and ask for explicit confirmation (e.g., "Confirm to bridge 100 USDC from Ethereum to Solana?").
4. **Execute**: Call `/api/v1/tx/bridge/lifi/execute` to sign and broadcast the transaction.
5. **Monitor**: If the status is `PENDING`, provide the `final_status_url` to the user or poll it until it reaches `DONE`.

## API Specification

All endpoints are under `/api/v1/tx/bridge/lifi/`.

### 1. Token Verification
Query supported tokens for specific chains to find exact contract addresses.
- **Endpoint**: `GET /api/v1/tx/bridge/lifi/tokens?chains={chainIDs}`
- **Parameters**: `chains` (comma-separated IDs, e.g., "1,56,1151111081099710, 9270000000000000").

### 2. Bridge Quote
Estimate cross-chain swap details.
- **Endpoint**: `POST /api/v1/tx/bridge/lifi/quote`
- **MANDATORY**: Before calling this, you MUST call `/api/v1/tx/bridge/lifi/tokens` to verify if the specific token is supported on both source and target chains.
- **Payload**: `LifiBridgeRequest`
  - `from_chain_id`: Source chain (e.g., ETH: '1', BSC: '56', Solana: '1151111081099710', Sui: '9270000000000000').
  - `from_token`: Source token address or symbol.
  - `to_chain_id`: Destination chain.
  - `to_token`: Destination token address or symbol.
  - `amount`: Smallest unit decimal string.
  - `from_address`: Source wallet address.
  - `to_address`: Recipient address.

### 3. Bridge Execution
Execute the cross-chain transaction.
- **Endpoint**: `POST /api/v1/tx/bridge/lifi/execute`
- **Payload**: Same as `quote`.
- **Handling PENDING**: If the response returns `status: "PENDING"`, use the `final_status_url` for tracking. **Do not retry** the execute call if it returns `PENDING`.

## Chain ID Reference

| Chain | ID |
|-------|----|
| Ethereum | 1 |
| BSC | 56 |
| Base | 8453 |
| Arbitrum | 42161 |
| Optimism | 10 |
| Polygon | 137 |
| Avalanche | 43114 |
| Linea | 59144 |
| Solana | 1151111081099710 |
| Sui | 9270000000000000 |

## Agent Instructions

1. **Token Support Pre-check**: **CRITICAL**. You MUST call `/api/v1/tx/bridge/lifi/tokens?chains={from_chain_id},{to_chain_id}` before requesting a quote or execution. This ensures the tokens are supported and provides the exact contract addresses required for stablecoins (USDT/USDC).
2. **EVM to Sui Optimization**: Direct EVM -> Sui takes ~15 mins. To reduce to ~3 mins, suggest routing through Solana:
   - Stage 1: EVM -> Solana (Target: USDC).
   - Stage 2: Solana -> Sui.
   - **Note**: Ensure the Solana wallet has at least 0.005 SOL for gas before starting.
3. **No Silent Retries**: If execution fails or times out, check the explorer first. Obtain user approval before any retry attempt.
4. **Bitcoin**: Note that Bitcoin is currently **not supported** by the LI.FI bridge.
