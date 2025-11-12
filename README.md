# Pixotchi Plant Contract Suite

Onchain horticulture powers every Pixotchi game loop.  
This repository contains the upgradeable smart contracts backing plant minting, growth, battles, accessories, and the in-game economy that surrounds them.

<p align="center">
  <img src="https://mini.pixotchi.tech/ecologo.png" alt="Pixotchi Logo" width="160">
</p>

[![Network](https://img.shields.io/badge/Base-Mainnet-0052FF?logo=coinbase&logoColor=white&style=flat-square)](https://basescan.org/address/0xeb4e16c804ae9275a655abbc20cd0658a91f9235)
[![Architecture](https://img.shields.io/badge/Standard-EIP--7504-6f3aff?style=flat-square)](https://blog.thirdweb.com/erc-7504-dynamic-smart-contracts/)
[![Upgradeable](https://img.shields.io/badge/Router-Dynamic%20Proxy-38B2AC?style=flat-square)](#architecture)
[![License](https://img.shields.io/badge/License-MIT-000?style=flat-square)](LICENSE)

---

## Mainnet Contracts

| Module | Address | Purpose |
| ------ | ------- | ------- |
| **Plant Router (Proxy)** | `0xeb4e16c804AE9275a655AbBc20cD0658A91F9235` | ERC‑7504 router exposing all plant functionality |
| **Land Diamond** | `0x3f1F8F0C4BE4bCeB45E6597AFe0dE861B8c3278c` | Linked land system (claims resources, assigns plant stats) |
| **SEED Token** | `0x546D239032b24eCEEE0cb05c92FC39090846adc7` | Primary payment/growth currency |
| **LEAF Token** | `0xE78ee52349D7b031E2A6633E07c037C3147DB116` | Reward currency used by accessories, quests, and staking |

Extensions are dynamically installed/uninstalled through the router; their addresses evolve over time. Always pull the live ABI from the router or the `extensions()` view.

---

## Architecture

Pixotchi Plants adopt [EIP‑7504 Dynamic Smart Contracts](https://blog.thirdweb.com/erc-7504-dynamic-smart-contracts/):

- **Router** – Minimal proxy that delegates to extension contracts determined by `msg.sig`.
- **Extensions** – Individual logic modules (NFT, games, shop, garden, etc.).
- **Composable ABI** – Router exposes an aggregated ABI, keeping clients simple and upgrade-safe.
- **Permission layer** – `PixotchiExtensionPermission` and router state gating ensure only authorised extensions are installed.

This architecture allows us to iterate on gameplay without replacing the proxy, while keeping storage layouts isolated per extension.

---

## Extension Overview

| Category | Extension | Summary |
| -------- | --------- | ------- |
| **Entrypoint** | `PixotchiRouter` | Initializes the contract, manages extensions, routes every call. |
| **NFT** | `NFTLogic`, `Renderer` | ERC-721 core mint/burn logic, metadata assembly, composable accessories. |
| **Gameplay** | `GameLogic`, `ConfigLogic`, `GameStorage` | Battle mechanics, strain configuration, kill rewards, shared storage. |
| **Minigames** | `BoxGame`, `SpinGame` | Onchain minigames providing bonus rewards and engagement loops. |
| **Garden** | `GardenLogic` | Accessory purchasing, garden upgrades, cosmetic metadata. |
| **Shop** | `ShopLogic` | Item catalog, pricing, and checkout flow. |
| **Utilities** | `FixedPointMathLib`, `PixotchiExtensionPermission`, `ERC2771ContextConsumer` | Math helpers, extension access control, meta-transaction context. |
| **Interfaces** | `IPixotchi`, `IToken` | Contract interfaces for external integrations and router tooling. |

Each extension is versioned; new deployments can replace specific modules without touching the rest of the system.

---

## Building & Testing

```bash
pnpm install
pnpm build         # compile extensions
pnpm test          # run Hardhat test suite
```

Targets:
- Solidity `^0.8.23`
- Node.js 18+
- Hardhat for local development

For script-driven installs and upgrades, review the `scripts/` directory. The router exposes helper functions to attach/detach extensions when deploying from code.

---

## Deploy / Upgrade Workflow

1. **Deploy new extension** – compile and deploy the replacement contract.
2. **Register in router** – call `PixotchiRouter.installExtension(extension, metadata)` from the owner account.
3. **Verify ABI** – ensure the router reflects the new function selectors.
4. **Deactivate legacy logic** (optional) – remove unused extensions for cleanliness.

Because the router handles delegation, state migrations happen inside the extension. Keep storage layout changes backward compatible or include migration hooks.

---

## Integrating With Land

The land diamond consumes plant APIs via:

- `landToPlantAssignPlantPoints` / `landToPlantAssignLifeTime`
- Cross-contract XP and resource routing

If you upgrade plant interfaces, maintain these entry points or coordinate a simultaneous land upgrade.

---

## License

MIT – see the root `LICENSE`.

Built with ❤️ for the Pixotchi community and its ever-growing gardens.
