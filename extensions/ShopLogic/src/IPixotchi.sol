// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


interface IArcade {
    event Played(uint256 indexed id, uint256 points, uint256 timeExtension, string gameName);

    event PlayedV2(uint256 indexed id, int256 points, int256 timeExtension, string gameName);
}


interface IBoxGame {
    function boxGameGetCoolDownTimePerNFT(uint256 nftID) external view returns (uint256);

    function boxGamePlay(uint256 nftID, uint256 seed) external returns (uint256 points, uint256 timeExtension);
}

interface ISpinGame {
    function spinGameGetCoolDownTimePerNFT(uint256 nftID) external view returns (uint256);

    function spinGamePlay(uint256 nftID, uint256 seed) external returns (int256 pointsAdjustment, int256 timeAdjustment, bool isPercentage);
    //function spinGamePlay(uint256 nftID, uint256 seed) external returns (uint256 points, uint256 timeExtension);
}

interface IConfig {

}



interface IShop {
    /// @notice Emitted when a shop item is created.
    /// @param id The ID of the shop item.
    /// @param name The name of the shop item.
    /// @param price The price of the shop item.
    /// @param expireTime The expiration time of the shop item.
    event ShopItemCreated(uint256 id, string name, uint256 price, uint256 expireTime);

    /// @notice Emitted when a shop item is purchased.
    /// @param nftId The ID of the NFT.
    /// @param buyer The address of the buyer.
    /// @param itemId The ID of the purchased item.
    event ShopItemPurchased(uint256 indexed nftId, address indexed buyer, uint256 indexed itemId);

    struct ShopItem {
        uint256 id;
        string name;
        uint256 price;
        uint256 effectTime; // for example 3 days timespan.
    }

    struct ShopItemOwned {
        uint256 id;
        string name;
        uint256 effectUntil; // in the future, per owner
        bool effectIsOngoingActive;
    }

    /// @notice Gets all shop items.
    /// @return ShopItem[] An array of all shop items.
    function shopGetAllItems() external view returns (ShopItem[] memory);

    /// @notice Gets the purchased shop items for a specific NFT.
    /// @param nftId The ID of the NFT.
    /// @return ShopItemOwned[] An array of owned shop items.
    function shopGetPurchasedItems(uint256 nftId) external view returns (ShopItemOwned[] memory);

    /// @notice Buys a shop item.
    /// @param nftId The ID of the NFT.
    /// @param itemId The ID of the item to buy.
    function shopBuyItem(uint256 nftId, uint256 itemId) external;

    /// @notice Checks if a shop item exists.
    /// @param itemId The ID of the item.
    /// @return bool True if the item exists, false otherwise.
    function shopDoesItemExist(uint256 itemId) external view returns (bool);

    /// @notice Checks if the effect of a shop item is still ongoing for an NFT.
    /// @param nftId The ID of the NFT.
    /// @param itemId The ID of the item.
    /// @return bool True if the effect is still ongoing, false otherwise.
    function shopIsEffectOngoing(uint256 nftId, uint256 itemId) external view returns (bool);
}

interface IGarden {
    // Define a struct to hold plant information
    struct FullItem {
        uint256 id;
        string name;
        uint256 price;
        uint256 points;
        uint256 timeExtension;
    }


    event ItemConsumed(uint256 nftId, address giver, uint256 itemId);

    event ItemCreated(uint256 id, string name, uint256 price, uint256 points);

    function getAllGardenItem() external view returns (FullItem[] memory);

    //function createItem(string calldata _name, uint256 _price, uint256 _points, uint256 _timeExtension) external;

    //function editItem(uint256 _id, uint256 _price, uint256 _points, string calldata _name, uint256 _timeExtension) external;


}

interface INFT {
    function mint(uint256 strain) external;

    function burn(uint256 id) external;

    function tokenBurnAndRedistribute(address account, uint256 amount) external;

    function removeTokenIdFromOwner(uint32 tokenId, address owner) external returns (bool);

    function getPlantScore(uint256 plantId) external view returns (uint256);

    function getPlantTimeUntilStarving(uint256 plantId) external view returns (uint256);

    function tokenURI(uint256 id) external view returns (string memory);

    function getPlantInfo(uint256 id) external view returns (IGame.PlantFull memory);

    function getPlantsInfo(uint256[] memory _nftIds) external view returns (IGame.PlantFull[] memory);

    function getPlantsByOwner(address _owner) external view returns (IGame.PlantFull[] memory);

    function getPlantInfoExtended(uint256 id) external view returns (IGame.PlantFull memory);

    function getPlantsInfoExtended(uint256[] memory _nftIds) external view returns (IGame.PlantFull[] memory);

    function getPlantsByOwnerExtended(address _owner) external view returns (IGame.PlantFull[] memory);

    event Mint(address to, uint256 strain, uint256 id);
}

interface IRenderer {
    function prepareTokenURI(IGame.PlantFull calldata plant, string calldata ipfsHash/*, string calldata status, uint256 level*/) external pure returns (string memory);
}

interface IGameExtensions {
    struct PlantExtensions {
        IShop.ShopItemOwned[] shopItemOwned;
    }
}

interface IGame {

    function getPlantName(uint256 id) external view returns (string memory);

    function isApprovedFn(uint256 id, address wallet) external view returns (bool);

    enum  Status {
        JOYFUL, //0
        THIRSTY, //1
        NEGLECTED, //2
        SICK, //3
        DEAD, //4,
        BURNED //5
    }

    struct Strain {
        uint256 id;
        uint256 mintPrice;
        uint256 totalSupply;
        uint256 totalMinted;
        uint256 maxSupply;
        string name;
        bool isActive;
        uint256 getStrainTotalLeft;
        uint256 strainInitialTOD;
    }

    struct Plant {
        uint256 id;
        string name;
        uint256 timeUntilStarving;
        uint256 score;
        uint256 timePlantBorn;
        uint256 lastAttackUsed;
        uint256 lastAttacked;
        uint256 stars;
        uint256 strain;
    }

    struct PlantFull {
        uint256 id;
        string name;
        uint256 timeUntilStarving;
        uint256 score;
        uint256 timePlantBorn;
        uint256 lastAttackUsed;
        uint256 lastAttacked;
        uint256 stars;
        uint256 strain;
        Status status;
        string statusStr;
        uint256 level;
        address owner;
        uint256 rewards;
        IGameExtensions.PlantExtensions[] extensions;
    }


    event Killed(
        uint256 nftId,
        uint256 deadId,
        string loserName,
        uint256 reward,
        address killer,
        string winnerName
    );


    event Attack(
        uint256 attacker,
        uint256 winner,
        uint256 loser,
        uint256 scoresWon
    );
    event RedeemRewards(uint256 indexed id, uint256 reward);

    event Pass(uint256 from, uint256 to);

    //event Mint(uint256 id);

    //event Played(uint256 indexed id, uint256 points, uint256 timeExtension);
    //event PlayedV2(uint256 indexed id, int256 points, int256 timeExtension);

    // Player functions
    //function mint(uint256 strain) external;
    function attack(uint256 fromId, uint256 toId) external;

    function kill(uint256 _deadId, uint256 _tokenId) external;

    function setPlantName(uint256 _id, string calldata _name) external;

    function pass(uint256 from, uint256 to) external;


    function isPlantAlive(uint256 _nftId) external view returns (bool);

    function pendingEth(uint256 plantId) external view returns (uint256);

    function level(uint256 tokenId) external view returns (uint256);

    function getStatus(uint256 plant) external view returns (IGame.Status);

    function statusToString(IGame.Status status) external pure returns (string memory);

    function getAllStrainInfo() external view returns (Strain[] memory);

//function createItem(string calldata _name, uint256 _price, uint256 _points, uint256 _timeExtension) external;
    //function editItem(uint256 _id, uint256 _price, uint256 _points, string calldata _name, uint256 _timeExtension) external;

    // Events
    //event PlantCreated(uint256 indexed _plantId, address indexed _owner);
    //event AttackOccurred(uint256 indexed _plantId, address indexed _attacker);
    //event KillOccurred(uint256 indexed _plantId, address indexed _killer);
    // event ItemCreated(uint256 indexed _itemId, string _name, uint256 _price, uint256 _points);
}


