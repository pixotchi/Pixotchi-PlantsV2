# Pixotchi V2

Pixotchi is a blockchain-based game where players can mint, grow, and battle digital plants. This repository contains the smart contracts for the Pixotchi game.

## Contracts Overview

### Entrypoint

- **PixotchiRouter.sol**: Main router contract that handles initialization, upgrades, and generic contract logic.

### NFT

- **NFTLogic.sol**: Handles the logic for minting, burning, and managing NFTs.
- **Renderer.sol**: Prepares the token URI for the NFTs.

### Minigames

- **BoxGame.sol**: Implements the Box Game logic.
- **SpinGame.sol**: Implements the Spin Game logic.

### Shop

- **ShopLogic.sol**: Manages the shop items and their purchases.

### Garden

- **GardenLogic.sol**: Manages garden-related logic, including buying accessories for plants.

### Game

- **GameLogic.sol**: Core game logic including attacking, killing, and redeeming rewards.
- **ConfigLogic.sol**: Configuration logic for setting up strains and other game parameters.
- **GameStorage.sol**: Storage layout for the game.

### Utilities

- **FixedPointMathLib.sol**: Library for fixed-point arithmetic.
- **PixotchiExtensionPermission.sol**: Manages permissions for extensions.
- **ERC2771ContextConsumer.sol**: Context variant with ERC2771 support.

### Interfaces

- **IPixotchi.sol**: Main interface for the Pixotchi game.
- **IToken.sol**: Interface for the token used in the game.

## Getting Started

### Prerequisites

- Node.js
- Hardhat
- Solidity ^0.8.23

### Installation

1. Clone the repository:

## EIP-7504: Dynamic Smart Contracts

Pixotchi V2 is based on [EIP-7504: Dynamic Smart Contracts](https://blog.thirdweb.com/erc-7504-dynamic-smart-contracts/) from thirdweb.com. This Ethereum standard introduces a client-friendly approach to one-to-many proxy contracts, enhancing the flexibility and upgradeability of smart contracts.

### How EIP-7504 Works

EIP-7504 standardizes the concept of dynamic contracts, which are proxy contracts that can delegate calls to multiple implementation contracts. This is achieved through a `Router` interface that includes a fallback function to delegate calls based on the function selector (`msg.sig`). The `Router` determines the appropriate implementation contract for each function call, allowing for modular and upgradeable contract design.

#### Key Components

1. **Router Interface**: Defines the fallback function and the method to get the implementation address for a function selector.
2. **RouterState Interface**: Manages the state of the router, including the extensions and their functions.
3. **Extensions**: Implementation contracts that contain the logic for specific functions. The router delegates calls to these extensions based on the function selector.

#### Benefits

- **Modularity**: Functions can be grouped into extensions, making the contract more modular and easier to upgrade.
- **Client Friendliness**: The standard ensures that the ABI is straightforward to interpret, facilitating client interactions.
- **Upgradeability**: Individual functions can be upgraded without affecting the entire contract, enhancing flexibility.

For more details, refer to the [blog post](https://blog.thirdweb.com/erc-7504-dynamic-smart-contracts/).


## License

Licensed under the MIT License. See the `LICENSE` file at the project root for details.

---

**Built with ❤️ for the Pixotchi community**
