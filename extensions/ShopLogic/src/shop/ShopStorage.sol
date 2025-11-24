// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IPixotchi.sol";
//import "../IRenderer.sol";
//import "../IToken.sol";

/**
 * @title ShopStorage
 * @dev Library for managing shop storage data.
 * @custom:storage-location erc7201:offers.storage
 * @notice This library provides storage and management for shop items.
 * @author  7118.eth
 */

library ShopStorage {
    /// @custom:storage-location erc7201:offers.storage
    bytes32 constant SHOP_STORAGE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("eth.pixotchi.shop.storage")) - 1)
        ) & ~bytes32(uint256(0xff));

    struct Data {
        uint256 shopItemCounter;
        mapping(uint256 => uint256) shopItemPrice;
        mapping(uint256 => uint256) shopItemTotalConsumed;
        mapping(uint256 => uint256) shopItemMaxSupply; // 0 means infinite supply
        mapping(uint256 => string) shopItemName;
        mapping(uint256 => bool) shopItemIsActive;
        mapping(uint256 => uint256) shopItemExpireTime; // 0 means no expiration
        mapping(uint256 => uint256) shopItemEffectTime; // Added mapping for shop item effect time
        // Shop mappings
        mapping(uint256 => uint256) shop_0_Fence_EffectUntil;
    }

    /**
     * @dev Returns the storage data for the shop.
     * @return data_ The storage data.
     */
    function data() internal pure returns (Data storage data_) {
        bytes32 position = SHOP_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
