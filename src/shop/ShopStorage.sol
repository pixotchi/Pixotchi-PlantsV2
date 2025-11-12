// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IPixotchi.sol";

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
        mapping(uint256 => uint256) shopItemMaxSupply;
        mapping(uint256 => string) shopItemName;
        mapping(uint256 => bool) shopItemIsActive;
        mapping(uint256 => uint256) shopItemExpireTime;
        mapping(uint256 => uint256) shopItemEffectTime;
        mapping(uint256 => uint256) shop_0_Fence_EffectUntil;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = SHOP_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

