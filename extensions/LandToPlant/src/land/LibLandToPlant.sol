// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../game/GameStorage.sol";
import {IGame} from "../IPixotchi.sol";
import {LandToPlantAssignPoints, LandToPlantAssignLifetime} from "./LandToPlantEvents.sol";

/**
 * @title LibLandToPlant
 * @author 7118.eth
 * @notice A library for managing plant-related operations in the game
 * @dev This library contains functions for calculating rewards, assigning points,
 *      and managing plant lifetimes
 */
library LibLandToPlant {

/**
 * @dev Calculates the reward debt for a plant based on its score and the accumulated ETH per share.
 *      Ensures that the multiplication does not overflow.
 * @param plantScore The score of the plant.
 * @param ethAccPerShare The accumulated ETH per share.
 * @param PRECISION The precision factor used in division.
 * @return The calculated reward debt for the plant.
 */
    function calculatePlantRewardDebt(
        uint256 plantScore,
        uint256 ethAccPerShare,
        uint256 PRECISION
    ) internal pure returns (uint256) {
        // Ensure multiplication does not overflow
        unchecked {
            uint256 product = plantScore * ethAccPerShare;
            require(
                ethAccPerShare == 0 || product / ethAccPerShare == plantScore,
                "Multiplication overflow"
            );
            return product / PRECISION;
        }
    }

/**
 * @dev Assigns additional points to a plant NFT, updates its reward debt, and increments total scores.
 *      Requires that the plant is alive and the added points are greater than zero.
 * @param _nftId The ID of the plant NFT.
 * @param _addedPoints The number of points to add to the plant's score.
 * @return _newPlantPoints The new total points of the plant after addition.
 */
    function assignPlantPoints(uint256 _nftId, uint256 _addedPoints) internal returns (uint256 _newPlantPoints) {
        require(IGame(address(this)).isPlantAlive(_nftId), "Plant is dead");
        require(_addedPoints > 0, "Points must be greater than 0");

        if (_s().plantScore[_nftId] > 0) {
            _s().ethOwed[_nftId] = IGame(address(this)).pendingEth(_nftId);
        }

        _s().plantScore[_nftId] += _addedPoints;

        _s().plantRewardDebt[_nftId] = calculatePlantRewardDebt(
            _s().plantScore[_nftId],
            _s().ethAccPerShare,
            _s().PRECISION
        );

        _s().totalScores += _addedPoints;

        _newPlantPoints = _s().plantScore[_nftId];

        emit LandToPlantAssignPoints(_nftId, _addedPoints, _newPlantPoints);

        return _newPlantPoints;
    }

/**
 * @dev Extends the lifetime of a plant NFT by adding more time until it starts starving.
 *      Requires that the added lifetime is greater than zero.
 * @param _nftId The ID of the plant NFT.
 * @param _lifetime The amount of lifetime to add to the plant.
 * @return _newLifetime The new total lifetime of the plant after addition.
 */
    function assignLifeTime(uint256 _nftId, uint256 _lifetime) internal returns(uint256 _newLifetime) {
        require (_lifetime > 0, "Points must be greater than 0");

        _s().plantTimeUntilStarving[_nftId] += _lifetime;

        _newLifetime = _s().plantTimeUntilStarving[_nftId];

        emit LandToPlantAssignLifetime(_nftId, _lifetime, _newLifetime);

        return _newLifetime;
    }

/**
 * @dev Returns the GameStorage data structure.
 * @return data The storage data for the game.
 */
    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }


}
