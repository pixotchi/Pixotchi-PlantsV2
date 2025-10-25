// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../game/GameStorage.sol";
import "../IPixotchi.sol";
import "../IToken.sol";
import "./SpinGameV2Storage.sol";

import "../utils/FixedPointMathLib.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "./lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../utils/PixotchiExtensionPermission.sol";

contract SpinGameV2 is IArcade, ReentrancyGuard, Initializable, PixotchiExtensionPermission {
    using FixedPointMathLib for uint256;

    uint256 private constant REVEAL_BLOCK_WINDOW = 256;

    /// @dev Emitted when the game reward configuration is updated.
    event SpinGameV2RewardUpdated(uint256 indexed index, int256 pointDelta, uint256 timeExtension, uint256 leafAmount);

    /// @dev Emitted after a play with the resolved reward details.
    event SpinGameV2Played(
        uint256 indexed nftId,
        address indexed player,
        uint256 indexed rewardIndex,
        int256 pointsDelta,
        uint256 timeAdded,
        uint256 leafAmount
    );

    /// @dev Emitted when a player commits to a spin.
    event SpinGameV2Committed(uint256 indexed nftId, address indexed player, bytes32 commitHash);

    /// @dev Emitted when a pending spin is forfeited without reveal.
    event SpinGameV2Forfeited(uint256 indexed nftId, address indexed player);

    /// @dev Base initialize function. Seed with default configuration.
    function SpinGameV2Initialize() external reinitializer(9) {
        SpinGameV2Storage.Data storage store = SpinGameV2Storage.data();

        store.coolDownTime = 6 hours;
        store.starCost = 1;
        store.leafToken = address(0xE78ee52349D7b031E2A6633E07c037C3147DB116);

        store.rewards[0] = SpinGameV2Storage.RewardConfig({pointDelta: 150, timeExtension: 0, leafAmount: 0});
        store.rewards[1] = SpinGameV2Storage.RewardConfig({pointDelta: 0, timeExtension: 12 hours, leafAmount: 0});
        store.rewards[2] = SpinGameV2Storage.RewardConfig({pointDelta: 50, timeExtension: 0, leafAmount: 0});
        store.rewards[3] = SpinGameV2Storage.RewardConfig({pointDelta: 0, timeExtension: 0, leafAmount: 50_000 * 1e18});
        store.rewards[4] = SpinGameV2Storage.RewardConfig({pointDelta: 0, timeExtension: 0, leafAmount: 0});
        store.rewards[5] = SpinGameV2Storage.RewardConfig({pointDelta: 0, timeExtension: 0, leafAmount: 0});
    }

    /*///////////////////////////////////////////////////////////////
                            Gameplay Logic
    //////////////////////////////////////////////////////////////*/

    function spinGameV2Commit(uint256 nftId, bytes32 commitHash) external nonReentrant {
        require(commitHash != bytes32(0), "SpinGameV2: empty commit");

        SpinGameV2Storage.Data storage store = SpinGameV2Storage.data();
        GameStorage.Data storage gs = GameStorage.data();

        address player = IERC721A(address(this)).ownerOf(nftId);
        require(player == msg.sender, "SpinGameV2: not owner");
        require(IGame(address(this)).isPlantAlive(nftId), "SpinGameV2: plant dead");

        SpinGameV2Storage.PendingSpin storage pending = store.pendingSpins[nftId];
        if (pending.player != address(0)) {
            uint256 expiryBlock = uint256(pending.commitBlock) + 1 + REVEAL_BLOCK_WINDOW;
            if (block.number > expiryBlock) {
                address previousPlayer = pending.player;
                delete store.pendingSpins[nftId];
                emit SpinGameV2Forfeited(nftId, previousPlayer);
            } else {
                revert("SpinGameV2: pending spin");
            }
        }

        uint256 nextAvailable = store.lastPlayed[nftId] + store.coolDownTime;
        require(block.timestamp >= nextAvailable, "SpinGameV2: cooldown");

        uint256 cost = store.starCost;
        require(gs.plantStars[nftId] >= cost, "SpinGameV2: insufficient stars");
        gs.plantStars[nftId] -= cost;

        pending.player = player;
        pending.commitBlock = uint64(block.number);
        pending.commitHash = commitHash;

        emit SpinGameV2Committed(nftId, player, commitHash);
    }

    function spinGameV2Play(uint256 nftId, bytes32 revealSecret)
        external
        nonReentrant
        returns (int256 pointsDelta, uint256 timeAdded, uint256 leafAmount, uint256 rewardIndex)
    {
        SpinGameV2Storage.Data storage store = SpinGameV2Storage.data();

        address player = IERC721A(address(this)).ownerOf(nftId);
        require(player == msg.sender, "SpinGameV2: not owner");
        require(IGame(address(this)).isPlantAlive(nftId), "SpinGameV2: plant dead");

        SpinGameV2Storage.PendingSpin storage pending = store.pendingSpins[nftId];
        require(pending.player == player, "SpinGameV2: no pending spin");
        require(pending.commitHash != bytes32(0), "SpinGameV2: invalid pending");

        bytes32 expectedCommit = keccak256(abi.encodePacked(player, nftId, revealSecret));
        require(expectedCommit == pending.commitHash, "SpinGameV2: invalid reveal");

        uint256 targetBlock = uint256(pending.commitBlock) + 1;
        require(block.number > targetBlock, "SpinGameV2: reveal too early");
        require(block.number <= targetBlock + REVEAL_BLOCK_WINDOW, "SpinGameV2: reveal expired");

        bytes32 entropy = blockhash(targetBlock);
        require(entropy != bytes32(0), "SpinGameV2: entropy unavailable");

        rewardIndex = _random(entropy, revealSecret, nftId, pending.commitHash, 0, 5);
        SpinGameV2Storage.RewardConfig memory reward = store.rewards[rewardIndex];

        (pointsDelta, timeAdded) = _applyScoreAndTimeReward(nftId, reward.pointDelta, reward.timeExtension);
        leafAmount = reward.leafAmount;

        if (leafAmount > 0) {
            require(store.leafToken != address(0), "SpinGameV2: leaf token not set");
            require(IToken(store.leafToken).transfer(player, leafAmount), "SpinGameV2: leaf transfer failed");
        }

        store.lastPlayed[nftId] = block.timestamp;
        delete store.pendingSpins[nftId];

        emit SpinGameV2Played(nftId, player, rewardIndex, pointsDelta, timeAdded, leafAmount);
        emit PlayedV2(nftId, pointsDelta, int256(timeAdded), "SpinGameV2");
    }

    function spinGameV2Forfeit(uint256 nftId) external {
        SpinGameV2Storage.Data storage store = SpinGameV2Storage.data();
        SpinGameV2Storage.PendingSpin storage pending = store.pendingSpins[nftId];
        require(pending.player != address(0), "SpinGameV2: no pending spin");
        require(
            pending.player == msg.sender || Permissions(address(this)).hasRole(bytes32(0), msg.sender),
            "SpinGameV2: not authorized"
        );

        address player = pending.player;
        delete store.pendingSpins[nftId];

        emit SpinGameV2Forfeited(nftId, player);
    }

    function spinGameV2GetCoolDownTimePerNFT(uint256 nftId) external view returns (uint256) {
        SpinGameV2Storage.Data storage store = SpinGameV2Storage.data();
        uint256 last = store.lastPlayed[nftId];
        if (last == 0) {
            return 0;
        }
        uint256 end = last + store.coolDownTime;
        if (block.timestamp >= end) {
            return 0;
        }
        return end - block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Controls
    //////////////////////////////////////////////////////////////*/

    function setCoolDownTime(uint256 newCoolDownTime) external onlyAdminRole {
        SpinGameV2Storage.data().coolDownTime = newCoolDownTime;
    }

    function setStarCost(uint256 newStarCost) external onlyAdminRole {
        SpinGameV2Storage.data().starCost = newStarCost;
    }

    function setLeafToken(address token) external onlyAdminRole {
        require(token != address(0), "SpinGameV2: zero address");
        SpinGameV2Storage.data().leafToken = token;
    }

    function setReward(uint256 index, int256 pointDelta, uint256 timeExtension, uint256 leafAmount)
        external
        onlyAdminRole
    {
        _validateRewardIndex(index);
        SpinGameV2Storage.data().rewards[index] = SpinGameV2Storage.RewardConfig({
            pointDelta: pointDelta,
            timeExtension: timeExtension,
            leafAmount: leafAmount
        });

        emit SpinGameV2RewardUpdated(index, pointDelta, timeExtension, leafAmount);
    }

    function setRewardPoints(uint256 index, int256 pointDelta) external onlyAdminRole {
        _validateRewardIndex(index);
        SpinGameV2Storage.data().rewards[index].pointDelta = pointDelta;
        emit SpinGameV2RewardUpdated(index, pointDelta, SpinGameV2Storage.data().rewards[index].timeExtension, SpinGameV2Storage.data().rewards[index].leafAmount);
    }

    function setRewardTime(uint256 index, uint256 timeExtension) external onlyAdminRole {
        _validateRewardIndex(index);
        SpinGameV2Storage.data().rewards[index].timeExtension = timeExtension;
        emit SpinGameV2RewardUpdated(index, SpinGameV2Storage.data().rewards[index].pointDelta, timeExtension, SpinGameV2Storage.data().rewards[index].leafAmount);
    }

    function setRewardLeaf(uint256 index, uint256 leafAmount) external onlyAdminRole {
        _validateRewardIndex(index);
        SpinGameV2Storage.data().rewards[index].leafAmount = leafAmount;
        emit SpinGameV2RewardUpdated(index, SpinGameV2Storage.data().rewards[index].pointDelta, SpinGameV2Storage.data().rewards[index].timeExtension, leafAmount);
    }

    /*///////////////////////////////////////////////////////////////
                            View Helpers
    //////////////////////////////////////////////////////////////*/

    function getCoolDownTime() external view returns (uint256) {
        return SpinGameV2Storage.data().coolDownTime;
    }

    function getStarCost() external view returns (uint256) {
        return SpinGameV2Storage.data().starCost;
    }

    function getLeafToken() external view returns (address) {
        return SpinGameV2Storage.data().leafToken;
    }

    function getReward(uint256 index)
        external
        view
        returns (int256 pointDelta, uint256 timeExtension, uint256 leafAmount)
    {
        _validateRewardIndex(index);
        SpinGameV2Storage.RewardConfig memory reward = SpinGameV2Storage.data().rewards[index];
        return (reward.pointDelta, reward.timeExtension, reward.leafAmount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Helpers
    //////////////////////////////////////////////////////////////*/

    function _applyScoreAndTimeReward(uint256 nftId, int256 pointDelta, uint256 timeExtension)
        internal
        returns (int256 appliedPoints, uint256 appliedTime)
    {
        GameStorage.Data storage gs = GameStorage.data();

        if (timeExtension > 0) {
            gs.plantTimeUntilStarving[nftId] += timeExtension;
            appliedTime = timeExtension;
        }

        if (pointDelta != 0) {
            if (pointDelta > 0) {
                uint256 unsignedDelta = uint256(pointDelta);

                if (gs.plantScore[nftId] > 0) {
                    gs.ethOwed[nftId] = IGame(address(this)).pendingEth(nftId);
                }

                gs.plantScore[nftId] += unsignedDelta;
                gs.plantRewardDebt[nftId] = gs.plantScore[nftId].mulDivDown(gs.ethAccPerShare, gs.PRECISION);
                gs.totalScores += unsignedDelta;
                appliedPoints = pointDelta;
            } else {
                uint256 absPoints = uint256(-pointDelta);
                if (absPoints >= gs.plantScore[nftId]) {
                    absPoints = gs.plantScore[nftId];
                    gs.plantScore[nftId] = 0;
                    gs.ethOwed[nftId] = 0;
                    gs.plantRewardDebt[nftId] = 0;
                } else {
                    gs.plantScore[nftId] -= absPoints;
                    gs.plantRewardDebt[nftId] = gs.plantScore[nftId].mulDivDown(gs.ethAccPerShare, gs.PRECISION);
                }

                if (absPoints <= gs.totalScores) {
                    gs.totalScores -= absPoints;
                } else {
                    gs.totalScores = 0;
                }

                appliedPoints = -int256(absPoints);
            }
        }
    }

    function _validateRewardIndex(uint256 index) internal pure {
        require(index < 6, "SpinGameV2: invalid index");
    }

    function _random(
        bytes32 entropy,
        bytes32 revealSecret,
        uint256 nftId,
        bytes32 commitHash,
        uint256 min,
        uint256 max
    ) internal pure returns (uint256) {
        uint256 range = max - min + 1;
        uint256 randomHash = uint256(keccak256(abi.encodePacked(entropy, revealSecret, nftId, commitHash)));
        return min + (randomHash % range);
    }
}
