// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.23;

import { InitStorage } from "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";

contract ReinitializerUtil {
    /**
     * @dev Reads the initialized counter from InitStorage.
     * @return The value of the initialized counter.
     */
    function getReinitializerCursor() external view returns (uint8) {
        return InitStorage.data().initialized;
    }
}