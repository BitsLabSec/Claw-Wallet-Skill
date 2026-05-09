---
name: claw-wallet-swap
description: "Use this skill for same-chain swaps through the Claw wallet sandbox on EVM, Solana, and Sui. It covers the exact sandbox endpoints, request fields, token normalization rules, raw amount units, provider fallback, approval handling, signing, and response handling for /api/v1/tx/swap/*."
---

# Claw Wallet Swap

Use this skill when the user wants to swap one asset for another on the same chain through the local wallet sandbox.

Supported routes:

- EVM: `POST /api/v1/tx/swap/evm`
- Solana: `POST /api/v1/tx/swap/solana`
- Sui: `POST /api/v1/tx/swap/sui`

## Critical Rules

1. Get explicit user confirmation before calling any swap endpoint.
2. Amount fields are raw smallest units of the input token, not always native units.
   - ETH input: wei.
   - ERC20 USDC input: USDC raw units, usually 6 decimals.
   - SOL input: lamports.
   - SPL USDC input: USDC raw units, usually 6 decimals, not lamports.
   - SUI input: MIST.
   - Sui non-native coin input: that coin type's raw units, not MIST.
3. Do not send human display amounts such as `"1.5"`. Convert to an integer string first.
4. Do not manually call approval endpoints. EVM swap performs required ERC20 approvals internally for supported providers.
5. Do not implement provider fallback in the agent. The sandbox handles fallback internally when an error is classified as retryable.
6. Use the active sandbox wallet. Do not add a `from` field; the sandbox resolves the signing address from the active signer context.
7. Request bodies use strict OpenAPI schemas with `additionalProperties: false`; do not send fields that are not listed for that endpoint.

## EVM Swap

Endpoint: `POST /api/v1/tx/swap/evm`

Provider order: `0x -> okx -> uniswap -> lifi`.

Supported chain names:

`ethereum`, `optimism`, `bsc`, `polygon`, `monad`, `base`, `arbitrum`, `avalanche`, `zksync`, `linea`

Minimal native-input payload:

```json
{
  "chain": "ethereum",
  "token_out": "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
  "amount_in_wei": "1000000000000000000"
}
```

Request schema: `EvmSwapTradeAPIRequest`

`additionalProperties: false`

Required fields:

- `chain`: target EVM chain. Must be one of `ethereum`, `optimism`, `bsc`, `polygon`, `monad`, `base`, `arbitrum`, `avalanche`, `zksync`, `linea`.
- `token_out`: output token contract address, or `native` for the chain native asset.
- `amount_in_wei`: positive decimal string in the input asset smallest unit.

Optional fields:

- `uid`: bound wallet UID for auditing / policy context.
- `token_in`: input token contract address, or `native` for the chain native asset. Omit to mean native.
- `routing_preference`: routing preference hint for Uniswap-compatible paths, e.g. `BEST_PRICE`.
- `protocols`: protocol allowlist for routing, case-insensitive, e.g. `V2`, `V3`, `UNISWAPX`.
- `urgency`: provider-specific urgency hint.
- `auto_slippage`: auto slippage mode, e.g. `DEFAULT` or `AUTO`.
- `slippage_tolerance`: integer basis points. When set, overrides auto slippage.
- `permit_amount`: Permit2 allowance amount setting for compatible providers, e.g. `FULL`.

Native token rule:

- Request native input with omitted `token_in` or `"native"`.
- Request native output with `"native"`.
- Do not use `0x0000000000000000000000000000000000000000` in requests. The sandbox uses that address in responses to represent native, but a request with the zero address can be treated like a normal token address by provider paths.

Token rule:

- Follow the OpenAPI contract: use contract addresses for non-native tokens and `native` for the chain native asset.
- The implementation can resolve a small set of built-in aliases on selected chains, but do not rely on aliases unless the caller already knows they are supported.

Response highlights:

- `provider`: selected provider, such as `0x`, `okx`, `uniswap`, or `lifi`.
- `approval_required`, `approval`, `approval_reset`, `permit`: EVM approval/permit steps if they were needed.
- `swap.tx_hash` / `swap.submitted_id`: submitted swap transaction identifiers.

## Solana Swap

Endpoint: `POST /api/v1/tx/swap/solana`

Provider behavior: Jupiter first; the sandbox may fall back to OKX.

Minimal payload:

```json
{
  "token_in": "native",
  "token_out": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
  "amount_in_wei": "100000000"
}
```

Request schema: `JupiterSwapRequest`

`additionalProperties: false`

Required fields:

- `token_out`: output token symbol or mint. Use `native` for SOL.
- `amount_in_wei`: positive decimal string in the input asset smallest unit. Must fit uint64 for Solana.

Optional fields:

- `chain`: must be `solana`; defaults to `solana` when omitted.
- `uid`: bound wallet UID for auditing / policy context.
- `token_in`: input token symbol or mint. Omit or use `native` for SOL.
- `slippage_bps`: integer basis points; defaults to `50` when omitted or 0.
- `payer`: payer override forwarded to the routing provider.
- `receiver`: receiver override forwarded to the routing provider.
- `exclude_routers`: router denylist forwarded to the routing provider.
- `exclude_dexes`: DEX denylist forwarded to the routing provider.
- `as_legacy_transaction`: deprecated. Omit or set `false`; legacy transactions are no longer supported.
- `wrap_and_unwrap_sol`: boolean; defaults true.
- `use_shared_accounts`: boolean; defaults true.
- `dynamic_compute_unit_limit`: boolean; defaults true.

Token symbol rule:

- Built-in symbols include `SOL`, `WSOL`, `USDC`, and `USDT`.
- Other non-address symbols are resolved via Jupiter token search and require an exact symbol match.

Response highlights:

- `provider`: `jupiter` or `okx`.
- `submitted_id` / `signature`: Solana transaction identifiers.
- `out_amount`, `other_amount_threshold`, `router`, `request_id`, `quote_id`: quote/execution metadata when provided.

## Sui Swap

Endpoint: `POST /api/v1/tx/swap/sui`

Provider: Cetus.

Example payload:

```json
{
  "chain": "sui",
  "token_in": "0x2::sui::SUI",
  "token_out": "USDC",
  "amount_wei": "1000000000",
  "slippage": 0.005
}
```

Request schema: `CetusSwapRequest`

`additionalProperties: false`

Required fields:

- `token_in`: input coin type or supported alias.
- `token_out`: output coin type or supported alias.
- `amount_wei`: positive decimal string in the input asset smallest unit.

Optional fields:

- `chain`: must be `sui`; defaults to `sui` when omitted.
- `uid`: bound wallet UID for auditing / policy context.
- `slippage`: ratio, e.g. `0.005` means 0.5%. Defaults to `0.005`; must be `<= 0.5`.

Token input rule:

- Supported native forms: `SUI`, `NATIVE`, or `0x2::sui::SUI`.
- Supported built-in stable symbols: `USDC`, `USDT` when configured for Sui mainnet.
- Full Sui coin types are accepted.
- Wrapped coin object type strings like `0x2::coin::Coin<...>` are unwrapped to the inner coin type.

Response highlights:

- `digest`: submitted Sui transaction digest/id.
- `sponsored`: whether gas sponsorship was used.
- `quote_amount_in`, `quote_amount_out`, `request_id`: Cetus route/build metadata.

## Before Calling

Confirm with the user using display amounts and symbols, then send raw integer units:

```text
Please confirm: swap 0.1 SOL to USDC on Solana with 0.5% slippage.
```

After confirmation, convert `0.1 SOL` to `100000000` and call the endpoint.

## Common Mistakes To Avoid

- Sending display amounts (`"0.1"`, `"1.5"`) instead of integer raw units.
- Sending EVM native as the zero address in request payloads.
- Assuming every `amount_in_wei` is native wei/lamports/MIST. It is raw input-token units.
- Setting Solana `as_legacy_transaction` to `true`.
- Adding `from`, `to`, or manually built transaction data to swap requests.
- Manually retrying providers from the agent prompt.
