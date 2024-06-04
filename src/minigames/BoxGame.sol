// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../game/GameStorage.sol";
import "../IPixotchi.sol";
import "./BoxGameStorage.sol";

import "../utils/FixedPointMathLib.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../utils/PixotchiExtensionPermission.sol";

contract BoxGame is
IBoxGame,
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
    function boxGameInitialize() public reinitializer(6) {
        _sMini().coolDownTime = 24 hours; // Default cooldown time.
        _sMini().nftContractRewardDecimals = 1e12; // Set the reward decimals.
        _sMini().pointRewards = [0, 75 * 1e12, 150 * 1e12, 200 * 1e12, 300 * 1e12]; // Initialize point rewards.
        _sMini().timeRewards = [0, 5 hours, 10 hours, 15 hours, 20 hours]; // Initialize time rewards.
    }


    function boxGameGetCoolDownTimePerNFT(uint256 nftID) public view override returns (uint256) {
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

    function boxGamePlay(uint256 nftID, uint256 seed) external override returns (uint256 points, uint256 timeExtension) {
        // Ensure the caller is the owner of the NFT and meets other requirements.
        require((IERC721A(address(this)).ownerOf(nftID) == msg.sender), "Not the owner of nft");
        //require(seed > 0 && seed < 10, "Seed should be between 1-9");
        require(boxGameGetCoolDownTimePerNFT(nftID) == 0, "Cool down time has not passed yet");
        require(IGame(address(this)).isPlantAlive(nftID), "Plant is dead");

        // Generate random indices for points and time rewards.
        uint256 pointsIndex = random(seed, 0, 4);
        points = _sMini().pointRewards[pointsIndex];
        uint256 timeIndex = random2(seed, 0, 4);
        timeExtension = _sMini().timeRewards[timeIndex];

        // Record the current time as the last played time for this NFT.
        _sMini().lastPlayed[nftID] = block.timestamp;

        // Update the NFT with new points and time extension.
        _updatePointsAndRewards(nftID, points, timeExtension);

        // Return the points and time extension.
        emit Played(nftID, points, timeExtension, "BoxGame");
        return (points, timeExtension);
    }




    function _updatePointsAndRewards(uint256 _nftId, uint256 _points, uint256 _timeExtension) internal {
        //require(IsAuthorized[msg.sender], "Not Authorized");

        if (_timeExtension != 0)
            _s().plantTimeUntilStarving[_nftId] += _timeExtension;

        if (_s().plantScore[_nftId] > 0) {
            _s().ethOwed[_nftId] = IGame(address(this)).pendingEth(_nftId);
        }

        _s().plantScore[_nftId] += _points;

        _s().plantRewardDebt[_nftId] = _s().plantScore[_nftId].mulDivDown(
        _s().ethAccPerShare,
            _s().PRECISION
        );

        _s().totalScores += _points;

    }

    function _updatePointsAndRewardsV2(uint256 _nftId, int256 _points, int256 _timeExtension) internal {
        //require(IsAuthorized[msg.sender], "Not Authorized");

        // Handling time extension adjustments
        if (_timeExtension != 0) {
            if (_timeExtension > 0 || uint256(- _timeExtension) <= _s().plantTimeUntilStarving[_nftId]) {
                // Safe to adjust time, whether adding or subtracting
                _s().plantTimeUntilStarving[_nftId] = uint256(int256(_s().plantTimeUntilStarving[_nftId]) + _timeExtension);
            } else {
                // Prevent underflow if trying to subtract more than the current value
                _s().plantTimeUntilStarving[_nftId] = 0;
            }
        }

        // Handling point adjustments
        if (_points != 0) {
            if (_points > 0 || uint256(- _points) <= _s().plantScore[_nftId]) {
                // Safe to adjust points, whether adding or subtracting
                _s().plantScore[_nftId] = uint256(int256(_s().plantScore[_nftId]) + _points);
            } else {
                // Prevent underflow if trying to subtract more than the current score
                _s().plantScore[_nftId] = 0;
            }

            // Adjust pending ETH, only if plantScore is positive
            if (_s().plantScore[_nftId] > 0) {
                _s().ethOwed[_nftId] = IGame(address(this)).pendingEth(_nftId);
            }

            // Recalculate reward debt, assuming plantScore did not underflow
            _s().plantRewardDebt[_nftId] = _s().plantScore[_nftId].mulDivDown(_s().ethAccPerShare, _s().PRECISION);
        }

        // Adjust total scores accordingly, checking for underflow and overflow
        if (_points > 0) {
            _s().totalScores += uint256(_points);
        } else if (_points < 0) {// Check if points are negative to avoid unnecessary operations when _points are 0
            uint256 absPoints = uint256(- _points);
            if (absPoints > 0) {// Proceed only if absPoints is greater than 0
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
    function boxGameSetGlobalCoolDownTime(uint256 _coolDownTime) public onlyAdminRole {
        _sMini().coolDownTime = _coolDownTime;
    }

    //set pointRewards
    function boxGameSetPointRewards(uint256[5] memory _pointRewards) public onlyAdminRole {
        _sMini().pointRewards = _pointRewards;
    }

    //set timeRewards
    function boxGameSetTimeRewards(uint256[5] memory _timeRewards) public onlyAdminRole {
        _sMini().timeRewards = _timeRewards;
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
    function _sMini() internal pure returns (BoxGameStorage.Data storage data) {
        data = BoxGameStorage.data();
    }

    /// @dev Returns the storage.
    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

}
