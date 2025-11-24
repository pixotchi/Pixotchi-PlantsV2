// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GameStorage.sol";
import "./DebugStorage.sol";
import "./../nft/ERC721AExtension.sol";
//import "../IPixotchi.sol";

//import "@openzeppelin/contracts/utils/Context.sol";

//import "../utils/FixedPointMathLib.sol";
//import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
//import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
//import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
//import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../utils/PixotchiExtensionPermission.sol";

contract AirdropLogic is PixotchiExtensionPermission {

    /// @notice Emitted when plant lifetimes are extended through an airdrop
    /// @param updatedPlantIds An array of plant token IDs that received the airdrop
    /// @param secondsAdded The number of seconds added to each plant's time until starving
    /// @param skippedPlantIds An array of plant token IDs that were skipped (burned or dead)
    event AirdropLifetimeExtended(uint256[] updatedPlantIds, uint256 secondsAdded, uint256[] skippedPlantIds);

    /// @notice Returns an array of token IDs for all alive plants
    /// @return An array of uint256 representing the token IDs of alive plants
    function airdropGetAliveTokenIds() public view returns (uint256[] memory) {
        uint256 currentIndex = _sN()._currentIndex;
        uint256[] memory aliveTokenIds = new uint256[](currentIndex);
        uint256 aliveCount = 0;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < currentIndex; i++) {
            if (!_sN()._ownerships[i].burned) {
                uint256 timeUntilStarving = _sG().plantTimeUntilStarving[i];
                if (timeUntilStarving != 0 && timeUntilStarving >= timestamp) {
                    aliveTokenIds[aliveCount++] = i;
                }
            }
        }

        // Resize the array to fit only the alive tokens
        assembly {
            mstore(aliveTokenIds, aliveCount)
        }

        return aliveTokenIds;
    }

    /// @notice Airdrops additional time to the specified plant IDs
    /// @param plantIds An array of plant token IDs to receive the airdrop
    /// @param secondsToAdd The number of seconds to add to each plant's time until starving
    function airdropExtendLifetime(uint256[] calldata plantIds, uint256 secondsToAdd) public onlyAdminRole {
        require(secondsToAdd > 0, "AirdropLogic: Seconds to add must be greater than zero");
        
        uint256 timestamp = block.timestamp;
        uint256[] memory updatedPlantIds = new uint256[](plantIds.length);
        uint256[] memory skippedPlantIds = new uint256[](plantIds.length);
        uint256 updatedCount = 0;
        uint256 skippedCount = 0;
        
        for (uint256 i = 0; i < plantIds.length; i++) {
            uint256 plantId = plantIds[i];
            if (_sN()._ownerships[plantId].burned) {
                skippedPlantIds[skippedCount++] = plantId;
                continue;
            }
            
            uint256 currentTimeUntilStarving = _sG().plantTimeUntilStarving[plantId];
            if (currentTimeUntilStarving <= timestamp) {
                skippedPlantIds[skippedCount++] = plantId;
                continue;
            }
            
            _sG().plantTimeUntilStarving[plantId] = currentTimeUntilStarving + secondsToAdd;
            updatedPlantIds[updatedCount++] = plantId;
        }
        
        // Resize the arrays to fit only the updated and skipped plant IDs
        assembly {
            mstore(updatedPlantIds, updatedCount)
            mstore(skippedPlantIds, skippedCount)
        }
        
        // Emit the event with the updated plant IDs, seconds added, and skipped plant IDs
        emit AirdropLifetimeExtended(updatedPlantIds, secondsToAdd, skippedPlantIds);
    }

    /// @notice Returns an array of token IDs for all alive & dead plants
    /// @return An array of uint256 representing the token IDs of alive & dead plants
    function airdropGetAliveAndDeadTokenIds() public view returns (uint256[] memory) {
        uint256 currentIndex = _sN()._currentIndex;
        uint256[] memory aliveTokenIds = new uint256[](currentIndex);
        uint256 count = 0;

        for (uint256 i = 0; i < currentIndex; i++) {
            if (!_sN()._ownerships[i].burned) {
                aliveTokenIds[count++] = i;
            }
        }

        // Resize the array 
        assembly {
            mstore(aliveTokenIds, count)
        }

        return aliveTokenIds;
    }

    /// @dev Returns the GameStorage.
    function _sG() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

        /// @dev Returns the ERC721AStorage.
    function _sN() internal pure returns (ERC721AStorage.Data storage data) {
        data = ERC721AStorage.erc721AStorage();
    }


}