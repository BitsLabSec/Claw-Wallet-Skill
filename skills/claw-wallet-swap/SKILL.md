---
name: claw-wallet-swap
description: "Same-chain asset swap skill for AI agents, enabling seamless token exchanges on EVM chains, Solana, and Sui using aggregated liquidity from Uniswap, 0x, OKX, Jupiter, and Cetus."
short_description: "Multi-chain same-chain asset swap."
default_prompt: "Use $skill-name to execute asset swaps on the same blockchain network, such as Ethereum, BSC, Solana, or Sui."
---

## Use this skill when...

Use this skill when the user wants to exchange one token for another on the same blockchain (e.g., ETH to USDC on Ethereum, or SOL to USDC on Solana).

Use this skill when the user wants to swap assets with optimized pricing through aggregated liquidity providers.

Use this skill when the user needs to perform a swap that might require token approval (EVM).

# swap skill

This skill provides a managed same-chain swap experience, integrating multiple liquidity aggregators and the local wallet sandbox for secure signing.

## Core Flow

To ensure a successful swap, the agent **MUST** follow these steps:

1. **User Confirmation**: Present the swap details (input token, output token, amount) to the user and ask for explicit confirmation (e.g., "Confirm to swap 1 ETH for USDC on Ethereum?").
2. **Execute Swap**: Call the appropriate chain-specific swap endpoint.
   - For EVM: `POST /api/v1/tx/swap/evm`
   - For Solana: `POST /api/v1/tx/swap/solana`
   - For Sui: `POST /api/v1/tx/swap/sui`
3. **Handle Response**: The sandbox automatically handles approvals (EVM) and transaction signing. Review the response for transaction hashes or status.

## API Specification

### 1. EVM Swap
Aggregated swap on EVM chains (Ethereum, BSC, Base, Arbitrum, etc.).
- **Endpoint**: `POST /api/v1/tx/swap/evm`
- **Payload**: `EvmSwapTradeAPIRequest`
  - `chain`: Target EVM chain (e.g., "ethereum", "bsc", "base", "arbitrum", "optimism", "polygon", "avalanche", "linea").
  - `token_in`: Input token address or "native".
  - `token_out`: Output token address or "native".
  - `amount_in_wei`: Input amount in smallest unit (decimal string).
  - `slippage_tolerance`: Optional slippage in basis points (e.g., 50 for 0.5%).
  - `uid`: Optional wallet UID.
- **Providers**: The sandbox automatically tries 0x, OKX, Uniswap, and LI.FI.

### 2. Solana Swap
Aggregated swap on Solana using Jupiter (with OKX fallback).
- **Endpoint**: `POST /api/v1/tx/swap/solana`
- **Payload**: `JupiterSwapRequest`
  - `token_in`: Input token symbol or mint address (use "native" for SOL).
  - `token_out`: Output token symbol or mint address.
  - `amount_in_wei`: Input amount in lamports (decimal string).
  - `slippage_bps`: Optional slippage in basis points (default: 50).
  - `uid`: Optional wallet UID.

### 3. Sui Swap
Swap on Sui using Cetus.
- **Endpoint**: `POST /api/v1/tx/swap/sui`
- **Payload**: `CetusSwapRequest`
  - `token_in`: Input coin type (e.g., "0x2::sui::SUI").
  - `token_out`: Output coin type.
  - `amount_wei`: Input amount in MIST (decimal string).
  - `slippage`: Optional slippage ratio (e.g., 0.005 for 0.5%).
  - `uid`: Optional wallet UID.

## Chain Reference

| Chain | Type | Common `token_in/out` for Native |
|-------|------|-----------------------------------|
| Ethereum | EVM | `native` or `0x0000000000000000000000000000000000000000` |
| BSC | EVM | `native` |
| Base | EVM | `native` |
| Solana | Solana | `native` |
| Sui | Sui | `0x2::sui::SUI` |

## Agent Instructions

1. **Explicit Confirmation**: **MANDATORY**. You MUST get user confirmation before calling any swap execution endpoint.
2. **Smallest Units**: Ensure `amount_in_wei` / `amount_wei` is provided in the smallest unit (wei for EVM, lamports for Solana, MIST for Sui).
3. **Symbol Resolution**: For Solana, symbols (e.g., "SOL", "USDC") are supported and resolved automatically. For EVM, contract addresses are preferred for non-native tokens.
4. **No Manual Approval**: On EVM, the managed swap handler automatically checks and executes required token approvals (ERC20 `approve`). Do not attempt to call approval endpoints manually unless the swap fails due to allowance issues.
5. **Fallback Logic**: The sandbox handles provider fallback internally (e.g., trying OKX if Jupiter fails on Solana). Do not implement manual fallback logic in the agent prompt.
