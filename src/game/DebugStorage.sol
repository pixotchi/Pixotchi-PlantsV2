// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IPixotchi.sol";
import "../IToken.sol";

/**
 * @author  7118.eth
 */
library DebugStorage {
    /// @custom:storage-location erc7201:offers.storage
    /// @dev use chisel cli tool from foundry to evaluate this expression
    /// @dev  keccak256(abi.encode(uint256(keccak256("eth.pixotchi.!!!-!!!_CHANGE_ME_!!!-!!!.storage")) - 1)) & ~bytes32(uint256(0xff))
    /// @custom:storage-location erc7201:offers.storage
    bytes32 constant DEBUG_STORAGE_POSITION =
    keccak256(
        abi.encode(uint256(keccak256("eth.pixotchi.debug.storage")) - 1)
    ) & ~bytes32(uint256(0xff));


    struct Data {
        mapping(address => mapping(uint32 => bool)) seenTokenIds;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = DEBUG_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }

}
