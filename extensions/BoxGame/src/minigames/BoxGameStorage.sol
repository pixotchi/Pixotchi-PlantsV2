// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IPixotchi.sol";
//import "../IRenderer.sol";
import "../IToken.sol";

/**
 * @author  7118.eth
 */
library BoxGameStorage {
    /// @custom:storage-location erc7201:offers.storage
    bytes32 constant BOX_GAME_STORAGE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("eth.pixotchi.box.game.storage")) - 1)
        ) & ~bytes32(uint256(0xff));

    struct Data {
        uint256 coolDownTime; // Cooldown time between plays for each NFT.
        uint256 nftContractRewardDecimals; // Decimals for reward calculation.
        mapping(uint256 => uint256) lastPlayed; // Tracks last played time for each NFT.
        uint256[5] pointRewards; // Array storing point rewards.
        uint256[5] timeRewards; // Array storing time rewards.
        mapping(uint256 => uint256) lastPlayedWithStar; // Tracks last played time with star.
        uint256 coolDownTimeStar; // Cooldown time between plays with star.
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = BOX_GAME_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
