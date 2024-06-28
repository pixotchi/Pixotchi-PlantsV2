// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GameStorage.sol";
import "../IPixotchi.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../utils/FixedPointMathLib.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
//import "../utils/ERC2771ContextConsumer.sol";

/**
 * @title GameLogic
 * @dev Implements the core game logic for the Pixotchi game.
 */
contract GameLogic is IGame, ReentrancyGuard/*, ERC2771ContextConsumer*/ {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;
    using SafeMathUpgradeable for uint256;

    /*///////////////////////////////////////////////////////////////
                        Constants / Immutables
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                              Modifiers
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to check if the caller is approved to perform actions on the given plant ID.
     * @param id The ID of the plant.
     */
    modifier isApproved(uint256 id) {
        require(
            IERC721A(address(this)).ownerOf(id) == msg.sender,
            "Not approved"
        );
        _;
    }

    /**
     * @dev Checks if the given wallet is approved for the specified plant ID.
     * @param id The ID of the plant.
     * @param wallet The address of the wallet.
     * @return bool True if the wallet is approved, false otherwise.
     */
    function isApprovedFn(uint256 id, address wallet) public view override returns (bool) {
        return (IERC721A(address(this)).ownerOf(id) == wallet);
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                receive ether function, interface support
    //////////////////////////////////////////////////////////////*/

    /*/////////////////////////////////////////////////////////////
                        External Game functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows a plant to attack another plant.
     * @param fromId The ID of the attacking plant.
     * @param toId The ID of the plant being attacked.
     */
    function attack(uint256 fromId, uint256 toId) external isApproved(fromId) nonReentrant {
        require(fromId != toId, "Can't hurt yourself");
        require(isPlantAlive(fromId), "your plant is dead");
        require(isPlantAlive(toId), "plant dead");

        (uint256 pct, uint256 odds, bool canAttack) = onAttack(fromId, toId);

        if (!canAttack) {
            return;
        }

        _s().plantLastAttackUsed[fromId] = block.timestamp;
        _s().plantLastAttacked[toId] = block.timestamp;

        uint256 loser;
        uint256 winner;

        uint256 _random = random(fromId + toId);

        if (_random > odds) {
            loser = fromId;
            winner = toId;
        } else {
            loser = toId;
            winner = fromId;
        }

        uint256 feePercentage = _s().PRECISION.mulDivDown(pct, 1000); // 0.5 pct
        uint256 prizeScore = _s().plantScore[loser].mulDivDown(feePercentage, _s().PRECISION);
        uint256 prizeDebt = _s().plantRewardDebt[loser].mulDivDown(feePercentage, _s().PRECISION);

        _s().plantScore[loser] -= prizeScore;
        _s().plantRewardDebt[loser] -= prizeDebt;

        _s().plantScore[winner] += prizeScore;
        _s().plantRewardDebt[winner] += prizeDebt;

        emit Attack(fromId, winner, loser, prizeScore);
    }

    /**
     * @dev Allows a player to kill a dead plant and claim its points.
     * @param _deadId The ID of the dead plant.
     * @param _tokenId The ID of the player's plant.
     */
    function kill(uint256 _deadId, uint256 _tokenId) external isApproved(_tokenId) nonReentrant {
        require(isPlantAlive(_tokenId), "your plant is dead");
        require(!isPlantAlive(_deadId), "The plant has to be dead to claim its points");

        if (_s().hasTheDiamond == _deadId) {
            _s().hasTheDiamond = _tokenId;
        }

        address ownerOfDead = IERC721A(address(this)).ownerOf(_deadId);

        _s().guardDisarmed = true;
        INFT(address(this)).removeTokenIdFromOwner(uint32(_deadId), ownerOfDead);
        _s().guardDisarmed = true;
        INFT(address(this)).burn(_deadId);
        _s().guardDisarmed = false;

        _s().plantStars[_tokenId] += 1;
        _redeem(_deadId, ownerOfDead);

        emit Killed(_tokenId, _deadId, _s().plantName[_deadId], 1, msg.sender, _s().plantName[_tokenId]);
    }

    /**
     * @dev Sets the name of a plant.
     * @param _id The ID of the plant.
     * @param _name The new name of the plant.
     */
    function setPlantName(uint256 _id, string memory _name) external isApproved(_id) {
        require(bytes(_name).length >= 2 && bytes(_name).length <= 10, "Name length must be between 2 and 10 characters");
        _s().plantName[_id] = _name;
    }

    /**
     * @dev Allows a player to pass the diamond to another plant.
     * @param from The ID of the plant passing the diamond.
     * @param to The ID of the plant receiving the diamond.
     */
    function pass(uint256 from, uint256 to) external isApproved(from) nonReentrant {
        require(_s().hasTheDiamond == from, "you don't have it");
        require(IERC721A(address(this)).ownerOf(to) != address(0x0), "don't burn it");

        _s().hasTheDiamond = to;

        emit Pass(from, to);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Redeems the rewards for a plant.
     * @param id The ID of the plant.
     */
    function redeem(uint256 id) public isApproved(id) nonReentrant {
        address ownerOfId = IERC721A(address(this)).ownerOf(id);
        _redeem(id, ownerOfId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Gets the name of a plant.
     * @param _id The ID of the plant.
     * @return string The name of the plant.
     */
    function getPlantName(uint256 _id) public view returns (string memory) {
        return _s().plantName[_id];
    }

    /**
     * @dev Gets information about all active strains.
     * @return IGame.Strain[] An array of active strains.
     */
    function getAllStrainInfo() external view returns (IGame.Strain[] memory) {
        GameStorage.Data storage s = _s();
        uint256 strainCount = s.strainCounter;
        uint256 activeStrainCount = 0;

        for (uint256 i = 0; i <= strainCount; i++) {
            if (s.strainIsActive[i]) {
                activeStrainCount++;
            }
        }

        IGame.Strain[] memory strains = new IGame.Strain[](activeStrainCount);
        uint256 index = 0;

        for (uint256 i = 0; i <= strainCount; i++) {
            if (s.strainIsActive[i]) {
                strains[index] = IGame.Strain({
                    id: i,
                    mintPrice: s.mintPriceByStrain[i],
                    totalSupply: s.strainTotalMinted[i] - s.strainBurned[i],
                    totalMinted: s.strainTotalMinted[i],
                    maxSupply: s.strainMaxSupply[i],
                    name: s.strainName[i],
                    isActive: s.strainIsActive[i],
                    getStrainTotalLeft: s.strainMaxSupply[i] - s.strainTotalMinted[i],
                    strainInitialTOD: s.strainInitialTOD[i]
                });
                index++;
            }
        }

        return strains;
    }

    /**
     * @dev Converts a Status enum to a string.
     * @param status The Status enum.
     * @return string The string representation of the status.
     */
    function statusToString(IGame.Status status) public pure returns (string memory) {
        if (status == IGame.Status.JOYFUL) {
            return "JOYFUL";
        } else if (status == IGame.Status.THIRSTY) {
            return "THIRSTY";
        } else if (status == IGame.Status.NEGLECTED) {
            return "NEGLECTED";
        } else if (status == IGame.Status.SICK) {
            return "SICK";
        } else if (status == IGame.Status.DEAD) {
            return "DEAD";
        } else if (status == IGame.Status.BURNED) {
            return "BURNED";
        }
        return ""; // Default case, should not happen
    }

    /**
     * @dev Gets the status of a plant.
     * @param plant The ID of the plant.
     * @return Status The status of the plant.
     */
    function getStatus(uint256 plant) public view returns (Status) {
        GameStorage.Data storage s = _s();

        if (s.burnedPlants[plant] || IERC721AExtension(address(this)).isBurned(plant)) {
            return Status.BURNED;
        }
        if (!isPlantAlive(plant)) {
            return Status.DEAD;
        }

        if (s.plantTimeUntilStarving[plant] > block.timestamp + 16 hours) {
            return Status.JOYFUL;
        }
        if (
            s.plantTimeUntilStarving[plant] > block.timestamp + 12 hours &&
            s.plantTimeUntilStarving[plant] < block.timestamp + 16 hours
        ) {
            return Status.THIRSTY;
        }
        if (
            s.plantTimeUntilStarving[plant] > block.timestamp + 8 hours &&
            s.plantTimeUntilStarving[plant] < block.timestamp + 12 hours
        ) {
            return Status.NEGLECTED;
        }
        if (s.plantTimeUntilStarving[plant] < block.timestamp + 8 hours) {
            return Status.SICK;
        }

        return Status.BURNED;
    }

    /**
     * @dev Gets the pending ETH rewards for a plant.
     * @param plantId The ID of the plant.
     * @return uint256 The pending ETH rewards.
     */
    function pendingEth(uint256 plantId) public view returns (uint256) {
        uint256 _ethAccPerShare = _s().ethAccPerShare;

        if (
            _s().plantScore[plantId].mulDivDown(_ethAccPerShare, _s().PRECISION) <
            _s().plantRewardDebt[plantId]
        ) {
            return _s().ethOwed[plantId];
        } else {
            return
                (_s().plantScore[plantId].mulDivDown(_ethAccPerShare, _s().PRECISION))
                .sub(_s().plantRewardDebt[plantId])
                .add(_s().ethOwed[plantId]);
        }
    }

    /**
     * @dev Checks if a plant is alive.
     * @param _nftId The ID of the plant.
     * @return bool True if the plant is alive, false otherwise.
     */
    function isPlantAlive(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = _s().plantTimeUntilStarving[_nftId];
        return _timeUntilStarving != 0 && _timeUntilStarving >= block.timestamp;
    }

    /**
     * @dev Handles an attack between two plants.
     * @param fromId The ID of the attacking plant.
     * @param toId The ID of the plant being attacked.
     * @return pct The percentage of the prize.
     * @return odds The odds of winning the attack.
     * @return canAttack True if the attack can proceed, false otherwise.
     */
    function onAttack(uint256 fromId, uint256 toId) public view returns (uint256 pct, uint256 odds, bool canAttack) {
        require(
            block.timestamp >= _s().plantLastAttackUsed[fromId] + 15 minutes ||
            _s().plantLastAttackUsed[fromId] == 0,
            "You have one attack every 15 mins"
        );
        require(
            block.timestamp > _s().plantLastAttacked[toId] + 1 hours,
            "can be attacked once every hour"
        );
        require(
            level(fromId) < level(toId),
            "Only attack plants above your level"
        );
        require(
            !IShop(address(this)).shopIsEffectOngoing(toId, 0),
            "Target plant is protected by a Fence"
        );

        pct = 5; // Set the percentage to 0.5%
        odds = 40; // Set the odds for the attacker as lower level to 40%
        canAttack = true; // Set canAttack to true
    }

    /**
     * @dev Gets the level of a plant.
     * @param tokenId The ID of the plant.
     * @return uint256 The level of the plant.
     */
    function level(uint256 tokenId) public view returns (uint256) {
        uint256 _score = _s().plantScore[tokenId] / 1e12;
        _score = _score / 100;
        if (_score == 0) {
            return 1;
        }
        uint256 _level = _sqrtu(_score * _s().la);
        return (_level * _s().lb);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Redeems the rewards for a plant.
     * @param id The ID of the plant.
     * @param _to The address to send the rewards to.
     */
    function _redeem(uint256 id, address _to) internal {
        uint256 pending = pendingEth(id);

        GameStorage.Data storage s = _s();
        s.totalScores -= s.plantScore[id];
        s.plantScore[id] = 0;
        s.ethOwed[id] = 0;
        s.plantRewardDebt[id] = 0;

        payable(_to).safeTransferETH(pending);

        emit RedeemRewards(id, pending);
    }

    /**
     * @dev Calculates the square root of a number, rounding down.
     * @param x The number to calculate the square root of.
     * @return uint128 The square root of the number.
     */
    function _sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }

    /**
     * @dev Generates a random number based on the given seed.
     * @param seed The seed for the random number generation.
     * @return uint The generated random number.
     */
    function random(uint256 seed) private view returns (uint) {
        uint hashNumber = uint(
            keccak256(
                abi.encodePacked(
                    seed,
                    block.prevrandao,
                    block.timestamp,
                    msg.sender
                )
            )
        );
        return hashNumber % 100;
    }

    /**
     * @dev Returns the game storage data.
     * @return data The game storage data.
     */
    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

//    function _msgData() internal view override(ERC2771ContextConsumer, Permissions) returns (bytes calldata) {
//        return ERC2771ContextConsumer._msgData();
//    }
//
//    function _msgSender() internal view override(ERC2771ContextConsumer, Permissions) returns (address sender) {
//        return ERC2771ContextConsumer._msgSender();
//    }
//

}
