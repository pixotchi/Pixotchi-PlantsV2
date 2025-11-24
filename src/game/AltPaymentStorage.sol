// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IToken.sol";

library AltPaymentStorage {
    /// @dev keccak256("pixotchi.alt.payment.storage")
    bytes32 constant STORAGE_POSITION = keccak256("pixotchi.alt.payment.storage");

    struct Data {
        IToken altToken;
        // Mapping to check if a strain uses the alt token
        mapping(uint256 => bool) isAltTokenStrain;
        // Mapping for specific price in alt token (if 0, falls back to standard price or error)
        mapping(uint256 => uint256) altTokenPrice; 
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

