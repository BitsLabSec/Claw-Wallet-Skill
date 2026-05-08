---
name: claw-wallet-pay-with-x402
description: "AI agent skill for discovering and interacting with x402 Bazaar services, featuring automated payment proof generation (EIP-3009) and execution."
---

## Use this skill when...

Use this skill when the user wants to find blockchain services or resources (e.g., price feeds, weather data, specialized APIs) in the x402 Bazaar.

Use this skill when the user wants to interact with a service that requires payment (HTTP 402 Payment Required).

Use this skill when the user provides an intent like "I want to buy PEPE token info" or "Access the premium price feed".

# x402 skill

This skill provides a managed experience for the x402 protocol, allowing agents to discover services and handle payments seamlessly using the local wallet sandbox.

## Core Flow

To ensure a successful x402 interaction, the agent **MUST** follow these steps:

1. **Search for Services**: Call `/api/v1/x402/search` with the user's query or intent to find relevant resources.
2. **Present Options**: Show the matched resources (title, description, score) to the user and ask which one they want to use.
3. **Execute with Payment**: Call `/api/v1/x402/pay_and_execute` with the selected resource.
   - The sandbox will first try to execute the request.
   - If the service returns a 402 challenge, the sandbox automatically generates an EIP-3009 payment proof (signature) and retries the execution.
4. **User Confirmation**: For `pay_and_execute`, the agent **MUST** ask for user confirmation before proceeding, especially if a payment is likely involved.

## API Specification

### 1. Search x402 Services
Search for resources in the x402 Bazaar.
- **Endpoint**: `GET /api/v1/x402/search?q={query}`
- **Parameters**:
  - `q`: Natural language query or keywords.
  - `intent`: Optional structured intent (e.g., "buy", "access").
  - `asset`: Optional asset keyword (e.g., "pepe", "usdc").
  - `network`: Optional network filter (e.g., "base", "ethereum").
  - `limit`: Max results (default 5, max 50).
- **Response**: A list of `resources` with scores and metadata.

### 2. Pay and Execute
Execute an x402 resource with automated payment handling.
- **Endpoint**: `POST /api/v1/x402/pay_and_execute`
- **Payload**: `x402PayAndExecuteRequest`
  - `resource`: The URL of the x402 resource.
  - `method`: HTTP method (e.g., "GET", "POST").
  - `body`: Optional request body.
  - `headers`: Optional request headers.
  - `network`: The network to use for payment (e.g., "base", "ethereum").
  - `valid_for_seconds`: TTL for the payment proof (default 300s).
- **Handling**: This managed endpoint handles the "402 Required" loop internally. If successful, the final response from the service is returned.

## Supported Networks (for Payment)

| Network | Alias |
|---------|-------|
| Ethereum | `ethereum`, `eip155:1` |
| Base | `base`, `eip155:8453` |
| Polygon | `polygon`, `eip155:137` |
| Base Sepolia | `base-sepolia`, `eip155:84532` |

## Agent Instructions

1. **Natural Language Search**: Use `/api/v1/x402/search` liberally to map user intents to actual Bazaar resources.
2. **Confirmation is Key**: Always ask "Confirm to access [Resource Title] which may require a payment?" before calling `pay_and_execute`.
3. **Handle 402 Loop**: Do not try to manually parse 402 headers or sign EIP-3009 messages. Use the `/api/v1/x402/pay_and_execute` endpoint to let the sandbox handle the complexity.
4. **EIP-3009 Standard**: Note that this skill currently supports the `exact` scheme using EIP-3009 (USD Coin) for payments on EVM chains.
