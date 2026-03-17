# Nox Confidential Contracts

Confidential smart contracts built on top of the [Nox protocol](https://github.com/iExec-Nox/nox-protocol-contracts).

This repository provides:

- `ERC7984`: a confidential fungible token standard implementation.
- `ERC7984Advanced`: the same interface using more gas efficient Nox primitives.
- `ERC20ToERC7984Wrapper`: wraps ERC-20 tokens into confidential tokens.
- `ERC20ToERC7984WrapperAdvanced`: more gas efficient variant of the wrapper.

## Quickstart

```bash
pnpm install
pnpm build
pnpm test
```

## Project Layout

- `contracts/interfaces`: public interfaces (`IERC7984`, `IERC20ToERC7984Wrapper`, receivers).
- `contracts/token`: token implementations and extensions.
