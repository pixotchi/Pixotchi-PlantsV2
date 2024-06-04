// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../IPixotchi.sol";
//import "../IRenderer.sol";
import "../IToken.sol";

/// @author thirdweb

//import { IOffers } from "../IMarketplace.sol";

/**
 * @author  thirdweb.com
 */
library GameStorage {
    /// @custom:storage-location erc7201:offers.storage
    /// @dev use chisel cli tool from foundry to evaluate this expression
    /// @dev  keccak256(abi.encode(uint256(keccak256("eth.pixotchi.game.storage")) - 1)) & ~bytes32(uint256(0xff))
    //bytes32  constant OFFERS_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("eth.pixotchi.game.storage")) - 1));// & ~bytes32(uint256(0xff));
    //0x7b88e42357d22f249e6991bc87bae4cbb3c3a6df3597089b20afdf487007e800;
    bytes32  constant GAME_STORAGE_POSITION = 0xc7fc9545a7a1c6d926eb226aca9b0331d15be911879e1d18bd76f146a8dc0000; //keccak256(abi.encode(uint256(keccak256("eth.pixotchi.game.storage")) - 1))  & ~bytes32(uint256(0xff))


    struct Data {
        uint256 PRECISION;// = 1 ether;
        IToken token;

        //uint256 _tokenIds;
        uint256 _itemIds;

        uint256 la;
        uint256 lb;

        // v staking
        mapping(uint256 => uint256) ethOwed;
        mapping(uint256 => uint256) plantRewardDebt;

        uint256 ethAccPerShare;

        uint256 totalScores;

        // items/benefits for the plant, general so can be food or anything in the future.
        mapping(uint256 => uint256) itemPrice;
        mapping(uint256 => uint256) itemPoints;
        mapping(uint256 => string) itemName;
        mapping(uint256 => uint256) itemTimeExtension;
        mapping(address => uint32[]) idsByOwner;
        mapping(uint32 => uint32) ownerIndexById;

        //mapping(address => bool) IsAuthorized;

        uint256 hasTheDiamond;
        //uint256 maxSupply;
        bool mintIsActive;
        address revShareWallet;
        uint256 burnPercentage;

        IRenderer renderer;

        mapping(uint256 => bool) burnedPlants;

        //strainCounter
        uint256 strainCounter;
        //mapping(uint256 => uint256) strainTotalSupply;
        mapping(uint256 => uint256) mintPriceByStrain;
        mapping(uint256 => uint256) strainBurned;
        mapping(uint256 => uint256) strainTotalMinted;
        mapping(uint256 => uint256) strainMaxSupply;
        mapping(uint256 => string) strainName;
        mapping(uint256 => bool) strainIsActive;
        mapping(uint256 => string) strainIPFSHash;
        //uint256[] strainIds;

        //shop Items
        uint256 shopItemCounter;
        mapping(uint256 => uint256) shopItemPrice;
        mapping(uint256 => uint256) shopItemTotalConsumed;
        mapping(uint256 => uint256) shopItemMaxSupply;
        mapping(uint256 => string) shopItemName;
        mapping(uint256 => bool) shopItemIsActive;
        mapping(uint256 => uint256) shopItemExpireTime;

        // Plant mappings
        mapping(uint256 => string) plantName;
        mapping(uint256 => uint256) plantTimeUntilStarving;
        mapping(uint256 => uint256) plantScore;
        mapping(uint256 => uint256) plantTimeBorn;
        mapping(uint256 => uint256) plantLastAttackUsed;
        mapping(uint256 => uint256) plantLastAttacked;
        mapping(uint256 => uint256) plantStars;
        mapping(uint256 => uint256) plantStrain;

        //mapping(uint256 => bool) approvedToBurn;

        bool guardDisarmed;

        // Shop mappings
        mapping(uint256 => uint256) shop_0_Fence_EffectUntil;

        mapping(uint256 => uint256) strainInitialTOD;

    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = GAME_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }

}
