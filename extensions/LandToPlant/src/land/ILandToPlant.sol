// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title ILandToPlant Interface
/// @author 7118.eth
/// @notice Interface for the LandToPlant contract, managing plant points and lifetime for NFTs
interface ILandToPlant {
    /// @notice Assigns plant points to an NFT
    /// @param _nftId The ID of the NFT
    /// @param _addedPoints The number of points to add
    /// @return _newPlantPoints The updated total plant points for the NFT
    function landToPlantAssignPlantPoints(uint256 _nftId, uint256 _addedPoints) external returns (uint256 _newPlantPoints);

    /// @notice Assigns lifetime to an NFT
    /// @param _nftId The ID of the NFT
    /// @param _lifetime The lifetime value to assign
    /// @return _newLifetime The updated lifetime for the NFT
    function landToPlantAssignLifeTime(uint256 _nftId, uint256 _lifetime) external returns (uint256 _newLifetime);
}