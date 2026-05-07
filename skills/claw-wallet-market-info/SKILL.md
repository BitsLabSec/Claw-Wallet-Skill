---
name: claw-wallet-market-info
description: "Comprehensive real-time crypto market data, news, and safety risk checks for AI agents, providing deep insights into price action, liquidity, and sentiment."
short_description: "Real-time market data, news, and risk checks."
default_prompt: "Use $skill-name to fetch market tickers, candles, order books, funding rates, and hot news to stay informed about the crypto market."
---

## Use this skill when...

Use this skill when the user wants to fetch real-time market data such as price tickers, K-line candles, order books, or recent trades.

Use this skill when the user wants to check advanced market metrics like funding rates, open interest, or price limits to assess crowding and holding costs.

Use this skill when the user wants to stay updated with the latest crypto news and trending categories.

Use this skill when the user needs to perform a risk check for a specific on-chain token or filter market assets based on specific criteria.

# market info skill

This skill provides a comprehensive suite of market intelligence tools for OpenClaw agents.

## API Specification

All endpoints are accessible via the sandbox API under `/api/v1/market/` and `/api/v1/news/`.

### 1. Market Filtering & Symbol Resolution
Before querying specific market data, use this endpoint to resolve the correct `instId` (e.g., 'BTC-USDT' or 'BTC-USDT-SWAP').
- **Endpoint**: `POST /api/v1/market/filter`
- **Payload**: `MarketFilterRequest`
  - `inst_type`: `SPOT`, `SWAP`, or `FUTURES`.
  - `filter_params`: Optional object. Use `baseCcy` (e.g., "BTC") and `quoteCcy` (e.g., "USDT") to find the exact instrument.

### 2. Market Data
- **Ticker**: Get latest price, 24h high/low, and 24h volume.
  - `GET /api/v1/market/ticker?symbol={instId}`
- **Candles**: Get historical K-line (OHLCV) data.
  - `GET /api/v1/market/candles?symbol={instId}&bar={interval}&limit={count}`
  - `bar`: '1m', '5m', '15m', '1H', '4H', '1D'.
- **Order Book**: Assess liquidity and slippage.
  - `GET /api/v1/market/books?symbol={instId}&sz={depth}` (Max sz: 400)
- **Recent Trades**: View individual trade density and volatility.
  - `GET /api/v1/market/trades?symbol={instId}&limit={count}` (Default: 20, Max: 500)

### 3. Advanced Metrics
- **Funding Rate**: Assess long/short crowding for perpetual swaps.
  - `GET /api/v1/market/funding-rate?symbol={instId}` (Note: `instId` must end with `-SWAP`)
- **Open Interest**: Observe market position scale changes.
  - `GET /api/v1/market/open-interest?inst_type={type}&symbol={instId}`
  - `inst_type`: `SWAP`, `FUTURES`, or `OPTION`.
- **Price Limit**: Avoid immediate order rejection by checking boundaries.
  - `GET /api/v1/market/price-limit?symbol={instId}`

### 4. News & Trending
**CRITICAL**: You MUST call categories first to get valid keys for hot news.
- **News Categories**: Retrieve valid category and subcategory keys.
  - `GET /api/v1/news/categories`
- **Hot News**: Get trending news articles and tweets.
  - `GET /api/v1/news/hot?category={key}&subcategory={optional_key}`
  - Example: `category="crypto"`, `subcategory="defi"`.

### 5. DEX Risk Assessment
For on-chain tokens, perform a security check using the contract address.
- **Endpoint**: `GET /api/v1/market/risk/check?chainId={id}&tokenContractAddress={addr}`
- **Chain IDs**: Ethereum: '1', Solana: '501', Sui: '784'.
- **Note**: Use `/api/v1/tx/bridge/lifi/tokens` to find the correct contract address, as `market/filter` only returns CEX pairs.

## Agent Instructions

1. **Symbol Resolution**: If this is the first time querying a symbol in a session, always use `/api/v1/market/filter` first to confirm the exact `instId` format used by the provider.
2. **News Flow**: Always fetch `/api/v1/news/categories` before requesting `/api/v1/news/hot` to ensure the category parameters are valid.
3. **DEX vs CEX**: Use `market/risk/check` for smart contract security on DEXes, and use `market/ticker` or `market/books` for trading activity on CEXes.
