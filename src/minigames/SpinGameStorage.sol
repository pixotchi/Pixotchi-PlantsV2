// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IPixotchi.sol";
//import "../IRenderer.sol";
import "../IToken.sol";

/**
 * @author  7118.eth
 */
library SpinGameStorage {
    /// @custom:storage-location erc7201:offers.storage
    bytes32 constant SPIN_GAME_STORAGE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("eth.pixotchi.spin.game.storage")) - 1)
        ) & ~bytes32(uint256(0xff));

//    struct Reward {
//        int256 points; // Can be negative for deductions.
//        int256 timeAdjustment; // Can be negative for reductions. Represented in seconds.
//        bool isPercentage; // True if the adjustments are percentage-based.
//    }

    struct Data {
        uint256 coolDownTime; // Cooldown time between plays for each NFT.
        uint256 nftContractRewardDecimals; // Decimals for reward calculation.
        mapping(uint256 => uint256) lastPlayed; // Tracks last played time for each NFT.
        mapping(uint256 => int256) pointRewards; // Mapping storing point rewards.
        mapping(uint256 => int256) timeRewards; // Mapping storing time rewards.
        mapping(uint256 => bool) isPercentage; // Mapping storing if the change is percentage-based.
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = SPIN_GAME_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
