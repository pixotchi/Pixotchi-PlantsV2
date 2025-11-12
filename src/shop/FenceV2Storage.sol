// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library FenceV2Storage {
    /// @custom:storage-location erc7201:fence.v2.storage
    bytes32 private constant FENCE_V2_STORAGE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("eth.pixotchi.fence.v2.storage")) - 1)
        ) & ~bytes32(uint256(0xff));

    struct Data {
        uint256 pricePerDay;
        mapping(uint256 => uint256) effectUntil;
        mapping(uint256 => uint256) totalDaysPurchased;
        uint256 totalPurchases;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = FENCE_V2_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

