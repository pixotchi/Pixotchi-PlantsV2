// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title SpinGameV2Storage
 * @dev Storage helpers for the SpinGame V2 extension.
 */
library SpinGameV2Storage {
    /// @custom:storage-location erc7201:spin.game.v2.storage
    bytes32 internal constant STORAGE_SLOT =
        keccak256(abi.encode(uint256(keccak256("eth.pixotchi.spin.game.v2.storage")) - 1)) &
            ~bytes32(uint256(0xff));

    struct RewardConfig {
        int256 pointDelta;        // Signed to allow boosts or penalties.
        uint256 timeExtension;    // Additional lifetime in seconds.
        uint256 leafAmount;       // ERC20 token reward amount.
    }

    struct PendingSpin {
        address player;           // Player that initiated the commitment.
        uint64 commitBlock;       // Block number when the commitment was made.
        bytes32 commitHash;       // Commitment hash provided by the player.
    }

    struct Data {
        uint256 coolDownTime;
        uint256 starCost;
        address leafToken;
        RewardConfig[6] rewards;
        mapping(uint256 => uint256) lastPlayed;
        mapping(uint256 => PendingSpin) pendingSpins;
    }

    function data() internal pure returns (Data storage store) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            store.slot := slot
        }
    }
}
