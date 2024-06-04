// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../game/GameStorage.sol";
import "../IPixotchi.sol";
import "./SpinGameStorage.sol";

//import "./ArcadeLibrary.sol";

import "../utils/FixedPointMathLib.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../utils/PixotchiExtensionPermission.sol";

contract SpinGame is
    ISpinGame,
    IArcade,
    ReentrancyGuard,
    Initializable,
    PixotchiExtensionPermission

    /**
     * @author 7118.eth
     */
{
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;
    using SafeMathUpgradeable for uint256;

    // Function to initialize the contract. Only callable once.
    function SpinGameInitialize() public reinitializer(7) {
        _sMini().coolDownTime = 24 hours; // Default cooldown time.
        _sMini().nftContractRewardDecimals = 1e12; // Set the reward decimals.

        // Initialize point rewards
        _sMini().pointRewards[0] = 0;
        _sMini().pointRewards[1] = 0;
        _sMini().pointRewards[2] = 75;
        _sMini().pointRewards[3] = 0;
        _sMini().pointRewards[4] = -10;
        _sMini().pointRewards[5] = 0;

        // Initialize time rewards
        _sMini().timeRewards[0] = 6 hours;
        _sMini().timeRewards[1] = 10;
        _sMini().timeRewards[2] = 0;
        _sMini().timeRewards[3] = -5;
        _sMini().timeRewards[4] = 0;
        _sMini().timeRewards[5] = 0;

        // Initialize isPercentage mapping
        _sMini().isPercentage[0] = false;
        _sMini().isPercentage[1] = true;
        _sMini().isPercentage[2] = false;
        _sMini().isPercentage[3] = true;
        _sMini().isPercentage[4] = true;
        _sMini().isPercentage[5] = false;
    }

    function spinGameGetCoolDownTimePerNFT(
        uint256 nftID
    ) public view override returns (uint256) {
        uint256 lastPlayedTime = _sMini().lastPlayed[nftID];
        // Return 0 if the NFT has never been played.
        if (lastPlayedTime == 0) {
            return 0;
        }
        // Check if the current time is less than the last played time (edge case).
        if (block.timestamp < lastPlayedTime) {
            return _sMini().coolDownTime;
        }
        // Calculate the time passed since last played.
        uint256 timePassed = block.timestamp - lastPlayedTime;
        // Return 0 if the cooldown has passed, otherwise return remaining time.
        if (timePassed >= _sMini().coolDownTime) {
            return 0;
        }
        return _sMini().coolDownTime - timePassed;
    }

    function spinGamePlay(
        uint256 nftID,
        uint256 seed
    ) external override returns (int256 pointsAdjustment, int256 timeAdjustment, bool isPercentage) {
        // Ensure the caller is the owner of the NFT and meets other requirements.
        require(
            (IERC721A(address(this)).ownerOf(nftID) == msg.sender),
            "Not the owner of nft"
        );
        require(
            spinGameGetCoolDownTimePerNFT(nftID) == 0,
            "Cool down time has not passed yet"
        );
        require(IGame(address(this)).isPlantAlive(nftID), "Plant is dead");

        // Generate random indices for points and time rewards.
        uint256 index = random(seed, 0, 5);
        isPercentage = _sMini().isPercentage[index];

        if (isPercentage) {
            if (_sMini().pointRewards[index] != 0) {
                pointsAdjustment =
                    (int256(INFT(address(this)).getPlantScore(nftID)) * _sMini().pointRewards[index]) /
                    100;
            }
            if (_sMini().timeRewards[index] != 0) {
                uint256 plantTimeUntilStarving = INFT(address(this)).getPlantTimeUntilStarving(nftID);
                uint256 remainingLifetime = plantTimeUntilStarving > block.timestamp ? plantTimeUntilStarving - block.timestamp : 0;
                timeAdjustment =
                    (int256(remainingLifetime) * _sMini().timeRewards[index]) /
                    100;
            }
        } else {
            pointsAdjustment = _sMini().pointRewards[index];
            timeAdjustment = _sMini().timeRewards[index];
        }

        // Record the current time as the last played time for this NFT.
        _sMini().lastPlayed[nftID] = block.timestamp;

        // Update the NFT with new points and time extension.
        _updatePointsAndRewardsV2(nftID, pointsAdjustment, timeAdjustment);

        // Return the points and time extension.
        emit PlayedV2(nftID, pointsAdjustment, timeAdjustment, "SpinGame");
        return (pointsAdjustment, timeAdjustment, isPercentage);
    }


    function _updatePointsAndRewardsV2(
        uint256 _nftId,
        int256 _points,
        int256 _timeExtension
    ) internal {
        //require(IsAuthorized[msg.sender], "Not Authorized");

        // Handling time extension adjustments
        if (_timeExtension != 0) {
            if (
                _timeExtension > 0 ||
                uint256(-_timeExtension) <= _s().plantTimeUntilStarving[_nftId]
            ) {
                // Safe to adjust time, whether adding or subtracting
                _s().plantTimeUntilStarving[_nftId] = uint256(
                    int256(_s().plantTimeUntilStarving[_nftId]) + _timeExtension
                );
            } else {
                // Prevent underflow if trying to subtract more than the current value
                _s().plantTimeUntilStarving[_nftId] = 0;
            }
        }

        // Handling point adjustments
        if (_points != 0) {
            if (_points > 0 || uint256(-_points) <= _s().plantScore[_nftId]) {
                // Safe to adjust points, whether adding or subtracting
                _s().plantScore[_nftId] = uint256(
                    int256(_s().plantScore[_nftId]) + _points
                );
            } else {
                // Prevent underflow if trying to subtract more than the current score
                _s().plantScore[_nftId] = 0;
            }

            // Adjust pending ETH, only if plantScore is positive
            if (_s().plantScore[_nftId] > 0) {
                _s().ethOwed[_nftId] = IGame(address(this)).pendingEth(_nftId);
            }

            // Recalculate reward debt, assuming plantScore did not underflow
            _s().plantRewardDebt[_nftId] = _s().plantScore[_nftId].mulDivDown(
                _s().ethAccPerShare,
                _s().PRECISION
            );
        }

        // Adjust total scores accordingly, checking for underflow and overflow
        if (_points > 0) {
            _s().totalScores += uint256(_points);
        } else if (_points < 0) {
            // Check if points are negative to avoid unnecessary operations when _points are 0
            uint256 absPoints = uint256(-_points);
            if (absPoints > 0) {
                // Proceed only if absPoints is greater than 0
                if (absPoints <= _s().totalScores) {
                    _s().totalScores -= absPoints;
                } else {
                    // Handle the case where totalScores cannot absorb the subtraction, e.g., set to 0 or revert
                    _s().totalScores = 0; // or revert with an error message
                }
            }
            // If absPoints is 0, no changes are made to totalScores
        }
        // No else block needed for _points == 0 as no changes are required in that scenario
    }

    // Function for the contract owner to set the global cooldown time.
    function spinGameSetCoolDownTime(uint256 _coolDownTime) public onlyAdminRole {
        _sMini().coolDownTime = _coolDownTime;
    }

    // Function to set point rewards.
    function spinGameSetPointRewards(uint256[] memory _pointRewards) public onlyAdminRole {
        require(_pointRewards.length == 6, "Invalid length for point rewards");
        for (uint256 i = 0; i < 6; i++) {
            _sMini().pointRewards[i] = int256(_pointRewards[i]);
        }
    }

    // Function to set time rewards.
    function spinGameSetTimeRewards(int256[] memory _timeRewards) public onlyAdminRole {
        require(_timeRewards.length == 6, "Invalid length for time rewards");
        for (uint256 i = 0; i < 6; i++) {
            _sMini().timeRewards[i] = _timeRewards[i];
        }
    }

    // Function to set isPercentage mapping.
    function spinGameSetIsPercentage(bool[] memory _isPercentage) public onlyAdminRole {
        require(_isPercentage.length == 6, "Invalid length for isPercentage");
        for (uint256 i = 0; i < 6; i++) {
            _sMini().isPercentage[i] = _isPercentage[i];
        }
    }

    //  function to generate a pseudo-random number based on several blockchain parameters.
    function random(uint256 seed, uint256 min, uint256 max) private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(blockhash(block.number-1), block.prevrandao, seed, block.number)));
        return min + (randomHash % (max - min + 1));
    }

    // Secondary  function for random number generation.
    function random2(uint256 seed, uint256 min, uint256 max) private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(seed, block.prevrandao, block.timestamp, msg.sender)));
        return min + (randomHash % (max - min + 1));
    }


    /// @dev Returns the storage.
    function _sMini()
        internal
        pure
        returns (SpinGameStorage.Data storage data)
    {
        data = SpinGameStorage.data();
    }

    /// @dev Returns the storage.
    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }
}
