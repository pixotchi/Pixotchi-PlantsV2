// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {LibLandToPlant} from "./LibLandToPlant.sol";
import {ILandToPlant} from "./ILandToPlant.sol";
import {LandAccessControl} from "./LandAccessControl.sol";

/**
 * @title LandToPlant
 * @author 7118.eth
 * @notice The extension ("facet") for managing plant-related operations in the game
 * @dev This contract contains functions for calculating rewards, assigning points,
 *      and managing plant lifetimes
 */
contract LandToPlant is ILandToPlant, LandAccessControl {

    /// @notice Assigns plant points to an NFT
    /// @dev Implements ILandToPlant.landToPlantAssignPlantPoints
    /// @param _nftId The ID of the NFT
    /// @param _addedPoints The number of points to add
    /// @return _newPlantPoints The updated total plant points for the NFT
    function landToPlantAssignPlantPoints(uint256 _nftId, uint256 _addedPoints) onlyAllowedCaller() /*onlyPlantOwner(_nftId)*/ external returns (uint256 _newPlantPoints)  {
        return LibLandToPlant.assignPlantPoints(_nftId, _addedPoints);
    }

    /// @notice Assigns lifetime to an NFT
    /// @dev Implements ILandToPlant.landToPlantAssignLifeTime
    /// @param _nftId The ID of the NFT
    /// @param _lifetime The lifetime value to assign
    /// @return _newLifetime The updated lifetime for the NFT
    function landToPlantAssignLifeTime(uint256 _nftId, uint256 _lifetime) onlyAllowedCaller() /*onlyPlantOwner(_nftId)*/ external returns(uint256 _newLifetime) {
        return LibLandToPlant.assignLifeTime(_nftId, _lifetime);
    }
}
