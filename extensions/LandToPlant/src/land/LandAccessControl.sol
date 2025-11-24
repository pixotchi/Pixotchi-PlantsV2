// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";

/**
 * @title LandAccessControl
 * @author 7118.eth
 * @notice Abstract contract for managing access control in land-related operations
 * @dev This contract provides modifiers for restricting access to certain functions
 */
abstract contract LandAccessControl {
    /// @notice Address of the allowed caller (temporary solution)
    address public immutable allowedCaller = 0xBd4FB987Bcd42755a62dCf657a3022B8b17D5413;

    /**
     * @notice Modifier to restrict access to the allowed caller
     * @dev Reverts if the caller is not the allowed address
     */
    modifier onlyAllowedCaller() {
        require(msg.sender == allowedCaller, "Caller is not allowed");
        _;
    }

//    /**
//     * @notice Modifier to restrict access to the owner of a specific NFT
//     * @dev Reverts if the caller is not the owner of the specified NFT
//     * @param nftId The ID of the NFT
//     */
//    modifier onlyPlantOwner(uint256 nftId) {
//        require((IERC721A(address(this)).ownerOf(nftId) == tx.origin), "tx.origin is not owner"); //doesnt work for AA
//        _;
//    }
    
}