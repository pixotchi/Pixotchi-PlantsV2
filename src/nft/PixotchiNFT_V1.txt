// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*

.-------. .-./`) _____     __   ,-----.  ,---------.   _______   .---.  .---..-./`)
\  _(`)_ \\ .-.')\   _\   /  /.'  .-,  '.\          \ /   __  \  |   |  |_ _|\ .-.')
| (_ o._)|/ `-' \.-./ ). /  '/ ,-.|  \ _ \`--.  ,---'| ,_/  \__) |   |  ( ' )/ `-' \
|  (_,_) / `-'`"`\ '_ .') .';  \  '_ /  | :  |   \ ,-./  )       |   '-(_{;}_)`-'`"`
|   '-.-'  .---.(_ (_) _) ' |  _`,/ \ _/  |  :_ _: \  '_ '`)     |      (_,_) .---.
|   |      |   |  /    \   \: (  '\_/ \   ;  (_I_)  > (_)  )  __ | _ _--.   | |   |
|   |      |   |  `-'`-'    \\ `"/  \  ) /  (_(=)_)(  .  .-'_/  )|( ' ) |   | |   |
/   )      |   | /  /   \    \'. \_/``".'    (_I_)  `-'`-'     / (_{;}_)|   | |   |
`---'      '---''--'     '----' '-----'      '---'    `._____.'  '(_,_) '---' '---'

https://t.me/Pixotchi
https://twitter.com/pixotchi
https://pixotchi.tech/
@audit https://blocksafu.com/
*/

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRenderer} from "./IRenderer.sol";
import {IToken} from "./IToken.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Constants.sol";


contract PixotchiNFT is OwnableUpgradeable, ERC721Upgradeable, ReentrancyGuardUpgradeable {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;
    using SafeMath for uint256;

    /*//////////////////////////////////////////////////////////////
                         state variables
    //////////////////////////////////////////////////////////////*/

    uint256 PRECISION;
    IToken public token;

    uint256 public _tokenIds;
    uint256 public _itemIds;

    uint256 public la;
    uint256 public lb;

    // plant properties
    mapping(uint256 => string) public plantName;
    mapping(uint256 => uint256) public timeUntilStarving;
    mapping(uint256 => uint256) public plantScore;
    mapping(uint256 => uint256) public timePlantBorn;
    mapping(uint256 => uint256) public lastAttackUsed;
    mapping(uint256 => uint256) public lastAttacked;
    mapping(uint256 => uint256) public stars;

    // v staking
    mapping(uint256 => uint256) public ethOwed;
    mapping(uint256 => uint256) public plantRewardDebt;

    uint256 public ethAccPerShare;

    uint256 public totalScores;// = 0;

    // items/benefits for the plant, general so can be food or anything in the future.
    mapping(uint256 => uint256) public itemPrice;
    mapping(uint256 => uint256) public itemPoints;
    mapping(uint256 => string) public itemName;
    mapping(uint256 => uint256) public itemTimeExtension;
    mapping(address => uint32[]) internal idsByOwner;
    mapping(uint32 => uint32) internal ownerIndexById;

    mapping(address => bool) private IsAuthorized;
    uint256 public Mint_Price;
    uint256 public hasTheDiamond;
    uint256 public maxSupply;
    bool public mintIsActive;
    address public revShareWallet;
    uint256 public burnPercentage;

    IRenderer public renderer;

    mapping(uint256 => bool) private burnedPlants;

    /*//////////////////////////////////////////////////////////////
                         events
    //////////////////////////////////////////////////////////////*/

    event ItemConsumed(uint256 nftId, address giver, uint256 itemId);

    event Killed(
        uint256 nftId,
        uint256 deadId,
        string loserName,
        uint256 reward,
        address killer,
        string winnerName
    );

    event ItemCreated(uint256 id, string name, uint256 price, uint256 points);

    event Attack(
        uint256 attacker,
        uint256 winner,
        uint256 loser,
        uint256 scoresWon
    );
    event RedeemRewards(uint256 indexed id, uint256 reward);

    event Pass(uint256 from, uint256 to);

    event Mint(uint256 id);

    event Played(uint256 indexed id, uint256 points, uint256 timeExtension);
    event PlayedV2(uint256 indexed id, int256 points, int256 timeExtension);

    /*//////////////////////////////////////////////////////////////
                         function modifiers
    //////////////////////////////////////////////////////////////*/

    modifier isApproved(uint256 id) {
        require(
            ownerOf(id) == msg.sender
            //|| getApproved[id] == msg.sender
            ,
            "Not approved"
        );

        _;
    }

    /*//////////////////////////////////////////////////////////////
                         struct, arrays or enums
    //////////////////////////////////////////////////////////////*/

    // Define a struct to hold plant information
    struct Plant {
        uint256 id;
        string name;
        Status status;
        uint256 score;
        uint256 level;
        uint256 timeUntilStarving;
        uint256 lastAttacked;
        uint256 lastAttackUsed;
        address owner;
        uint256 rewards;
        uint256 stars;
    }

    /// @dev  Define a struct that includes all item properties along with the id
    struct FullItem {
        uint256 id;
        string name;
        uint256 price;
        uint256 points;
        uint256 timeExtension;
    }

    /*//////////////////////////////////////////////////////////////
       constructor, initialize state variables within constructor
    //////////////////////////////////////////////////////////////*/


    function initialize(address _token, address _renderer) public initializer {
        __ERC721_init("Pixotchi", "PIX");
        __Ownable_init();
        token = IToken(_token);
        renderer = IRenderer(_renderer);
        PRECISION = 1 ether;
        la = 2;
        lb = 2;
        totalScores = 0;
        Mint_Price = 100 * 1e18;
        maxSupply = 20_000;
        mintIsActive = true;
        revShareWallet = msg.sender; //temporary wallet
        burnPercentage = 0; // 0-100%
    }

    /*//////////////////////////////////////////////////////////////
                receive ether function, interface support
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        ethAccPerShare += msg.value.mulDivDown(PRECISION, totalScores);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    /*//////////////////////////////////////////////////////////////
                        Mint functions
    //////////////////////////////////////////////////////////////*/

    function mint() public nonReentrant {
        require(mintIsActive, "Mint is closed");
        require(_tokenIds < maxSupply, "Over the limit");
        tokenBurnAndRedistribute(msg.sender, Mint_Price);

        timeUntilStarving[_tokenIds] = block.timestamp + 1 days;
        timePlantBorn[_tokenIds] = block.timestamp;

        addTokenIdToOwner(uint32(_tokenIds), msg.sender);
        // mint NFT
        _mint(msg.sender, _tokenIds);
        emit Mint(_tokenIds);
        _tokenIds++;
    }

    /*//////////////////////////////////////////////////////////////
                        internal functions
    //////////////////////////////////////////////////////////////*/

    function tokenBurnAndRedistribute(address account, uint256 amount) internal {
        uint256 _burnPercentage = burnPercentage;  // Assume burnPercentage is accessible here

        // Calculate the burn amount based on the provided amount
        uint256 _burnAmount = amount.mulDivDown(_burnPercentage, 100);

        // Calculate the amount for revShareWallet
        uint256 _revShareAmount = amount.mulDivDown(100 - _burnPercentage, 100);

        // Burn the calculated amount of tokens
        if (_burnAmount > 0) {
            token.transferFrom(account, address(0), _burnAmount);
        }

        // Transfer the calculated share of tokens to the revShareWallet
        if (_revShareAmount > 0) {
            token.transferFrom(account, revShareWallet, _revShareAmount);
        }
    }


    function addTokenIdToOwner(uint32 tokenId, address owner) internal {
        ownerIndexById[tokenId] = uint32(idsByOwner[owner].length);
        idsByOwner[owner].push(tokenId);
    }

    function removeTokenIdFromOwner(uint32 tokenId, address owner) internal returns(bool) {
        uint32[] storage ids = idsByOwner[owner];
        uint256 balance = ids.length;

        uint32 index = ownerIndexById[tokenId];
        if (ids[index] != tokenId) {
            return false;
        }
        uint32 movingId = ids[index] = ids[balance - 1];
        ownerIndexById[movingId] = index;
        ids.pop();

        return true;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) {
        } else if (to == address(0)) {
        } else {
            removeTokenIdFromOwner(uint32(tokenId), from);
            addTokenIdToOwner(uint32(tokenId), to);
        }
    }


    function _redeem(uint256 id, address _to) internal {
        uint256 pending = pendingEth(id);

        totalScores -= plantScore[id];
        plantScore[id] = 0;
        ethOwed[id] = 0;
        plantRewardDebt[id] = 0;

        payable(_to).safeTransferETH(pending);

        emit RedeemRewards(id, pending);
    }

    // Override the _burn function to track burned plant IDs
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        burnedPlants[tokenId] = true; // Mark the plant ID as burned
    }

    /*//////////////////////////////////////////////////////////////
                        ...
    //////////////////////////////////////////////////////////////*/

    function buyAccessory(
        uint256 nftId,
        uint256 itemId
    ) external payable isApproved(nftId) nonReentrant {
        require(itemExists(itemId), "This item doesn't exist");
        require(isPlantAlive(nftId), "plant dead"); //no revives

        uint256 amount = itemPrice[itemId];

        // recalculate time until starving
        timeUntilStarving[nftId] += itemTimeExtension[itemId];

        if (plantScore[nftId] > 0) {
            ethOwed[nftId] = pendingEth(nftId);
        }

        if (!isPlantAlive(nftId)) {
            plantScore[nftId] = itemPoints[itemId];
        } else {
            plantScore[nftId] += itemPoints[itemId];
        }

        plantRewardDebt[nftId] = plantScore[nftId].mulDivDown(
            ethAccPerShare,
            PRECISION
        );

        totalScores += itemPoints[itemId];

        //token.burnFrom(msg.sender, amount);
        tokenBurnAndRedistribute(msg.sender, amount);

        emit ItemConsumed(nftId, msg.sender, itemId);
    }

    function attack(uint256 fromId, uint256 toId) external isApproved(fromId) nonReentrant {
        require(fromId != toId, "Can't hurt yourself");
        require(isPlantAlive(fromId), "your plant is dead");
        require(isPlantAlive(toId), "plant dead");

        (uint256 pct, uint256 odds, bool canAttack) = onAttack(
            fromId,
            toId
        );

        if (!canAttack) {
            return;
        }

        lastAttackUsed[fromId] = block.timestamp;
        lastAttacked[toId] = block.timestamp;

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

        uint256 feePercentage = PRECISION.mulDivDown(pct, 1000); // 0.5 pct
        uint256 prizeScore = plantScore[loser].mulDivDown(
            feePercentage,
            PRECISION
        );

        uint256 prizeDebt = plantRewardDebt[loser].mulDivDown(
            feePercentage,
            PRECISION
        );

        plantScore[loser] -= prizeScore;
        plantRewardDebt[loser] -= prizeDebt;

        plantScore[winner] += prizeScore;
        plantRewardDebt[winner] += prizeDebt;

        emit Attack(fromId, winner, loser, prizeScore);
    }

    // kill and burn plants and get in game stars.
    function kill(
        uint256 _deadId,
        uint256 _tokenId
    ) external isApproved(_tokenId) nonReentrant {
        require(
            !isPlantAlive(_deadId),
            "The plant has to be dead to claim its points"
        );

        if (hasTheDiamond == _deadId) {
            hasTheDiamond = _tokenId;
        }

        address ownerOfDead = ownerOf(_deadId);

        removeTokenIdFromOwner(uint32(_deadId) , ownerOfDead);

        _burn(_deadId);
        stars[_tokenId] += 1;
        // redeem for dead plant
        _redeem(_deadId, ownerOfDead);

        emit Killed(
            _tokenId,
            _deadId,
            plantName[_deadId],
            1,
            msg.sender,
            plantName[_tokenId]
        );
    }

    function setPlantName(
        uint256 _id,
        string memory _name
    ) external isApproved(_id) {
        plantName[_id] = _name;
    }

    // just side quest for later to add to ui, one thing in the game that can be passed to other players
    function pass(uint256 from, uint256 to) external isApproved(from) nonReentrant  {
        require(hasTheDiamond == from, "you don't have it");
        require(ownerOf(to) != address(0x0), "don't burn it");

        hasTheDiamond = to;

        emit Pass(from, to);
    }

    // for updating from future contracts
    function updatePointsAndRewards(uint256 _nftId, uint256 _points, uint256 _timeExtension) external {
        require(IsAuthorized[msg.sender] , "Not Authorized");

        if(_timeExtension != 0)
            timeUntilStarving[_nftId] += _timeExtension;

        if (plantScore[_nftId] > 0) {
            ethOwed[_nftId] = pendingEth(_nftId);
        }

        plantScore[_nftId] += _points;

        plantRewardDebt[_nftId] = plantScore[_nftId].mulDivDown(
            ethAccPerShare,
            PRECISION
        );

        totalScores += _points;

        emit Played(_nftId, _points, _timeExtension);
    }

    function updatePointsAndRewardsV2(uint256 _nftId, int256 _points, int256 _timeExtension) external {
        require(IsAuthorized[msg.sender], "Not Authorized");

        // Handling time extension adjustments
        if (_timeExtension != 0) {
            if (_timeExtension > 0 || uint256(-_timeExtension) <= timeUntilStarving[_nftId]) {
                // Safe to adjust time, whether adding or subtracting
                timeUntilStarving[_nftId] = uint256(int256(timeUntilStarving[_nftId]) + _timeExtension);
            } else {
                // Prevent underflow if trying to subtract more than the current value
                timeUntilStarving[_nftId] = 0;
            }
        }

        // Handling point adjustments
        if (_points != 0) {
            if (_points > 0 || uint256(-_points) <= plantScore[_nftId]) {
                // Safe to adjust points, whether adding or subtracting
                plantScore[_nftId] = uint256(int256(plantScore[_nftId]) + _points);
            } else {
                // Prevent underflow if trying to subtract more than the current score
                plantScore[_nftId] = 0;
            }

            // Adjust pending ETH, only if plantScore is positive
            if (plantScore[_nftId] > 0) {
                ethOwed[_nftId] = pendingEth(_nftId);
            }

            // Recalculate reward debt, assuming plantScore did not underflow
            plantRewardDebt[_nftId] = plantScore[_nftId].mulDivDown(ethAccPerShare, PRECISION);
        }

        // Adjust total scores accordingly, checking for underflow and overflow
        if (_points > 0) {
            totalScores += uint256(_points);
        } else if (_points < 0) { // Check if points are negative to avoid unnecessary operations when _points are 0
            uint256 absPoints = uint256(-_points);
            if (absPoints > 0) { // Proceed only if absPoints is greater than 0
                if (absPoints <= totalScores) {
                    totalScores -= absPoints;
                } else {
                    // Handle the case where totalScores cannot absorb the subtraction, e.g., set to 0 or revert
                    totalScores = 0; // or revert with an error message
                }
            }
            // If absPoints is 0, no changes are made to totalScores
        }
        // No else block needed for _points == 0 as no changes are required in that scenario

        emit PlayedV2(_nftId, _points, _timeExtension);
    }



    function getAllTokenIdsOfOwner(address owner) public view returns (uint32[] memory ids) {
        ids = idsByOwner[owner];
    }

    function balanceOfOwner(address owner) public view returns(uint balance) {
        balance = idsByOwner[owner].length;
    }



    // Function to handle an attack
    function onAttack(
        uint256 fromId, // ID of the attacker
        uint256 toId // ID of the one being attacked
    ) public view returns (uint256 pct, uint256 odds, bool canAttack) {
        // Ensure the attacker can only attack once every 15 minutes
        require(
            block.timestamp >= lastAttackUsed[fromId] + 15 minutes ||
            lastAttackUsed[fromId] == 0,
            "You have one attack every 15 mins"
        );
        // Ensure the one being attacked can only be attacked once every hour
        require(
            block.timestamp > lastAttacked[toId] + 1 hours,
            "can be attacked once every hour"
        );

        // Ensure the attacker can only attack plants above their level
        require(
            level(fromId) < level(toId),
            "Only attack plants above your level"
        );

        pct = 5; // Set the percentage to 0.5%
        odds = 40; // Set the odds for the attacker as lower level to 40%
        canAttack = true; // Set canAttack to true
    }


    // function getByOwner(address owner) public view returns (uint32[] memory) {
    //     return idsByOwner[owner];
    // }


    /*//////////////////////////////////////////////////////////////
                        Utils
    //////////////////////////////////////////////////////////////*/



    /*//////////////////////////////////////////////////////////////
                        Game Getters
    //////////////////////////////////////////////////////////////*/

    function getStatus(uint256 plant) public view returns (Status) {
        if (burnedPlants[plant]) {
            return Status.BURNED;
        }
        if (!isPlantAlive(plant)) {
            return Status.DEAD;
        }

        if (timeUntilStarving[plant] > block.timestamp + 16 hours)
            return Status.JOYFUL;
        if (
            timeUntilStarving[plant] > block.timestamp + 12 hours &&
            timeUntilStarving[plant] < block.timestamp + 16 hours
        ) return Status.THIRSTY;

        if (
            timeUntilStarving[plant] > block.timestamp + 8 hours &&
            timeUntilStarving[plant] < block.timestamp + 12 hours
        ) return Status.NEGLECTED;

        if (timeUntilStarving[plant] < block.timestamp + 8 hours)
            return Status.SICK;

        return Status.BURNED;
    }

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(itemName[itemId]).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    // check that Plant didn't starve
    function isPlantAlive(uint256 _nftId) public view returns (bool) {
        uint256 _timeUntilStarving = timeUntilStarving[_nftId];
        if (_timeUntilStarving != 0 && _timeUntilStarving >= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function getItemInfo(
        uint256 _itemId
    )
    public
    view
    returns (
        string memory _name,
        uint256 _price,
        uint256 _points,
        uint256 _timeExtension
    )
    {
        _name = itemName[_itemId];
        _price = itemPrice[_itemId];
        _timeExtension = itemTimeExtension[_itemId];
        _points = itemPoints[_itemId];
    }


    /// @dev  Function to retrieve information about all items
    function getAllItemsInfo() public view returns (FullItem[] memory) {
        FullItem[] memory items = new FullItem[](_itemIds);

        for (uint256 i = 0; i < _itemIds; i++) {
            items[i] = FullItem({
                id: i,
                name: itemName[i],
                price: itemPrice[i],
                points: itemPoints[i],
                timeExtension: itemTimeExtension[i]
            });
        }
        return items;
    }


    function getPlantInfo(uint256 _nftId) public view returns (Plant memory) {
        Plant memory plant;
        plant.id = _nftId;
        plant.name = plantName[_nftId];
        plant.status = getStatus(_nftId);
        plant.score = plantScore[_nftId];
        plant.level = level(_nftId);
        plant.timeUntilStarving = timeUntilStarving[_nftId];
        plant.lastAttacked = lastAttacked[_nftId];
        plant.lastAttackUsed = lastAttackUsed[_nftId];
        plant.owner = !isPlantAlive(_nftId) && plant.score == 0 ? address(0x0) : ownerOf(_nftId);
        plant.rewards = pendingEth(_nftId);
        plant.stars = stars[_nftId];
        return plant;
    }

    function getPlantsInfo(uint256[] memory _nftIds) public view returns (Plant[] memory) {
        Plant[] memory tempPlants = new Plant[](_nftIds.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < _nftIds.length; i++) {
            Plant memory _plant = getPlantInfo(_nftIds[i]);
            if(_plant.status != Status.BURNED) { // Skip burned or unwanted plants
                tempPlants[validCount] = _plant;
                validCount++;
            }
        }

        // Now copy the valid plants into a new array of the correct size
        Plant[] memory plants = new Plant[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            plants[i] = tempPlants[i];
        }

        return plants;
    }


    function getPlantsByOwner(address _owner) public view returns (Plant[] memory) {
        uint32[] memory _nftIds = getAllTokenIdsOfOwner(_owner);
        Plant[] memory plants = new Plant[](_nftIds.length);

        for (uint32 i = 0; i < _nftIds.length; i++) {
            plants[i] = getPlantInfo(_nftIds[i]);
        }

        return plants;
    }




//    function getState() public view returns ( uint256 tokenIds, uint256 itemIds ) {
//       tokenIds = _tokenIds;
//       itemIds = _itemIds;
//    }

    /*//////////////////////////////////////////////////////////////
                        Metadata
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 _score = plantScore[id];
        uint256 _level = level(id);
        Status _status = getStatus(id);

        return renderer.prepareTokenURI(id, _score, _level, _status);
    }

    function risksAndAcknowledgement() external pure returns (string memory) {
        return
            "Do not spend money on this unless you are going to play the game, everything in crypto is risky. inspired by frenPet.xyz.";
    }


    // calculate level based on points
    function level(uint256 tokenId) public view returns (uint256) {
        // This is the formula L(x) = 2 * sqrt(x * 2)

        uint256 _score = plantScore[tokenId] / 1e12;
        _score = _score / 100;
        if (_score == 0) {
            return 1;
        }
        uint256 _level = _sqrtu(_score * la);
        return (_level * lb);
    }

    /*//////////////////////////////////////////////////////////////
                         Virtual Staking Logic
    //////////////////////////////////////////////////////////////*/

    function pendingEth(uint256 plantId) public view returns (uint256) {
        uint256 _ethAccPerShare = ethAccPerShare;

        //plantRewardDebt can sometimes be bigger by 1 wei do to several mulDivDowns so we do extra checks
        if (
            plantScore[plantId].mulDivDown(_ethAccPerShare, PRECISION) <
            plantRewardDebt[plantId]
        ) {
            return ethOwed[plantId];
        } else {
            return
                (plantScore[plantId].mulDivDown(_ethAccPerShare, PRECISION))
                .sub(plantRewardDebt[plantId])
                .add(ethOwed[plantId]);
        }
    }


    function redeem(uint256 id) public isApproved(id) nonReentrant {
        _redeem(id, ownerOf(id));
    }

    /*//////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/

    function authorizeAddress(address account, bool authorized) public onlyOwner {
        IsAuthorized[account] = authorized;
    }

    function setConfig(uint256 _Price, uint256 _maxSupply, bool _mintIsActive, uint256 _burnPercentage) public onlyOwner {
        require(_burnPercentage <= 100, "Burn percentage can't be more than 100");
        Mint_Price = _Price;
        maxSupply = _maxSupply;
        mintIsActive = _mintIsActive;
        burnPercentage = _burnPercentage;
    }

    function setRenderer(IRenderer _renderer) external onlyOwner {
        renderer = _renderer;
    }

    function setRevShareWallet(address _revShareWallet) external onlyOwner {
        revShareWallet = _revShareWallet;
    }

    function setToken(address _token) external onlyOwner {
        token = IToken(_token);
    }

    // add items/accessories
    function createItem(
        string calldata name,
        uint256 price,
        uint256 points,
        uint256 timeExtension
    ) public onlyOwner {
        uint256 newItemId = _itemIds;
        itemName[newItemId] = name;
        itemPrice[newItemId] = price;
        itemPoints[newItemId] = points;
        itemTimeExtension[newItemId] = timeExtension;

        _itemIds++;

        emit ItemCreated(newItemId, name, price, points);
    }



    // New function to create multiple items
    function createItems(FullItem[] calldata items) external onlyOwner {
        //we are ignoring the id in the struct and using the index of the array
        for (uint i = 0; i < items.length; i++) {
            createItem(items[i].name, items[i].price, items[i].points, items[i].timeExtension);
        }
    }



    function editItem(
        uint256 _id,
        uint256 _price,
        uint256 _points,
        string calldata _name,
        uint256 _timeExtension
    ) public onlyOwner {
        itemPrice[_id] = _price;
        itemPoints[_id] = _points;
        itemName[_id] = _name;
        itemTimeExtension[_id] = _timeExtension;
    }

    // New function to edit multiple items
    function editItems(FullItem[] calldata updates) external onlyOwner {
        for (uint i = 0; i < updates.length; i++) {
            editItem(
                updates[i].id,
                updates[i].price,
                updates[i].points,
                updates[i].name,
                updates[i].timeExtension
            );
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
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

    // ok for the use case, game.
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




}
