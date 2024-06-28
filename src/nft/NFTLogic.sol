// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../game/GameStorage.sol";
import "../IPixotchi.sol";
import "../utils/FixedPointMathLib.sol";
//import "../utils/ERC2771ContextConsumer.sol";

import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/contracts/eip/ERC721AUpgradeable.sol";
import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";

/**
 * @title NFTLogic
 * @dev This contract handles the logic for minting, burning, and managing NFTs in the Pixotchi game.
 */
contract NFTLogic is
    INFT,
    ReentrancyGuard,
    ERC721AUpgradeable //,
    //ERC2771ContextConsumer
    //Context
{
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
     * @dev Modifier to guard functions.
     *
     * This modifier only allows the function to be executed if the guard is disarmed.
     * The guard is disarmed if `_s().guardDisarmed` is true. After the function executes,
     * or if it fails before execution, `guardDisarmed` is set to false, preventing further
     * calls until it is explicitly disarmed again.
     *
     * This function is intended to protect public functions, ensuring that they can only
     * be accessed by other ERC-7504 extensions and by the router, but not by any other entity.
     *
     * Requirements:
     * - `_s().guardDisarmed` must be true.
     *
     * Emits no events.
     */
    modifier guard() {
        require(_s().guardDisarmed, "Guard is not disarmed");
        _s().guardDisarmed = false;
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the NFTLogic contract.
     * Sets up the initial state of the contract, including the token, admin, and revenue share wallet addresses.
     */
    function initializeNFTLogic() public reinitializer(5) {
        address _token = 0x546D239032b24eCEEE0cb05c92FC39090846adc7;
        address _defaultAdmin = 0x44e156CBb4506cee55A96b45D10A77806E012469;

        address _revShareWallet = 0x93023ED94724af40Da8dd7AD03304fB28F1765d6;

        __ERC721A_init("Pixotchi", "PIX");

        _s().token = IToken(_token);
        _s().mintIsActive = true;
        _s().revShareWallet = _revShareWallet;
        _s().burnPercentage = 1; // 0-100%
    }

    /*//////////////////////////////////////////////////////////////
                receive ether function, interface support
    //////////////////////////////////////////////////////////////*/

    //    receive() external payable {
    //        _s().ethAccPerShare += msg.value.mulDivDown(_s().PRECISION, _s().totalScores);
    //    }

    //    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable)
    //    returns (bool) {
    //        return super.supportsInterface(interfaceId);
    //    }

    /*///////////////////////////////////////////////////////////////
                    external write functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints a new NFT with the specified strain.
     * @param strain The strain of the NFT to be minted.
     */
    function mint(uint256 strain) external {
        _mintTo(strain, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                    external guarded write functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Burns tokens and redistributes them according to the burn percentage.
     * @param account The account from which tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function tokenBurnAndRedistribute(
        address account,
        uint256 amount
    ) external guard {
        _tokenBurnAndRedistribute(account, amount);
    }

    /**
     * @dev Removes a token ID from the owner's list of tokens.
     * @param tokenId The ID of the token to be removed.
     * @param owner The address of the owner.
     * @return bool indicating success.
     */
    function removeTokenIdFromOwner(
        uint32 tokenId,
        address owner
    ) external guard returns (bool) {
        return _removeTokenIdFromOwner(tokenId, owner);
    }

    /**
     * @dev Burns a specified token ID.
     * @param tokenId The ID of the token to be burned.
     */
    function burn(uint256 tokenId) external guard {
        super._burn(tokenId);
        _s().burnedPlants[tokenId] = true;
        _s().strainBurned[_s().plantStrain[tokenId]]++;
    }

    /*/////////////////////////////////////////////////////////////
                        Game functions
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the score of a plant.
     * @param plantId The ID of the plant.
     * @return The score of the plant.
     */
    function getPlantScore(
        uint256 plantId
    ) public view override returns (uint256) {
        return _s().plantScore[plantId];
    }

    /**
     * @dev Returns the time until a plant starts starving.
     * @param plantId The ID of the plant.
     * @return The time until the plant starts starving.
     */
    function getPlantTimeUntilStarving(
        uint256 plantId
    ) public view override returns (uint256) {
        return _s().plantTimeUntilStarving[plantId];
    }

    /**
     * @dev Returns the token URI for a given token ID.
     * @param id The ID of the token.
     * @return The token URI.
     */
    function tokenURI(
        uint256 id
    ) public view override(ERC721AUpgradeable, INFT) returns (string memory) {
        IGame.PlantFull memory plant = getPlantInfo(id);
        string memory ipfsHash = _s().strainIPFSHash[plant.strain];

        return IRenderer(address(this)).prepareTokenURI(plant, ipfsHash);
    }

    /**
     * @dev Returns detailed information about a plant.
     * @param id The ID of the plant.
     * @param withExtensions Whether to include extensions in the plant information.
     * @return The detailed information about the plant.
     */
    function _getPlantInfo(
        uint256 id,
        bool withExtensions
    ) private view returns (IGame.PlantFull memory) {
        IGame.Plant memory plant = IGame.Plant({
            id: id,
            name: _s().plantName[id],
            timeUntilStarving: _s().plantTimeUntilStarving[id],
            score: _s().plantScore[id],
            timePlantBorn: _s().plantTimeBorn[id],
            lastAttackUsed: _s().plantLastAttackUsed[id],
            lastAttacked: _s().plantLastAttacked[id],
            stars: _s().plantStars[id],
            strain: _s().plantStrain[id]
        });

        uint256 level = IGame(address(this)).level(plant.id);
        IGame.Status status = IGame(address(this)).getStatus(plant.id);

        string memory statusStr = IGame(address(this)).statusToString(status); // Convert status enum to string

        address plantOwner = (
            !IGame(address(this)).isPlantAlive(id) && plant.score == 0
                ? address(0x0)
                : IERC721A(address(this)).ownerOf(id)
        );

        IGameExtensions.PlantExtensions[] memory extensions;
        if (withExtensions) {
            extensions = new IGameExtensions.PlantExtensions[](1);
            extensions[0] = IGameExtensions.PlantExtensions({
                shopItemOwned: IShop(address(this)).shopGetPurchasedItems(id)
            });
        }

        return
            IGame.PlantFull({
                id: plant.id,
                name: plant.name,
                timeUntilStarving: plant.timeUntilStarving,
                score: plant.score,
                timePlantBorn: plant.timePlantBorn,
                lastAttackUsed: plant.lastAttackUsed,
                lastAttacked: plant.lastAttacked,
                stars: plant.stars,
                strain: plant.strain,
                status: status,
                statusStr: statusStr,
                level: level,
                owner: plantOwner,
                rewards: IGame(address(this)).pendingEth(id),
                extensions: extensions
            });
    }

    /**
     * @dev Returns detailed information about a plant.
     * @param id The ID of the plant.
     * @return The detailed information about the plant.
     */
    function getPlantInfo(
        uint256 id
    ) public view returns (IGame.PlantFull memory) {
        return _getPlantInfo(id, false);
    }

    /**
     * @dev Returns detailed information about a plant, including extensions.
     * @param id The ID of the plant.
     * @return The detailed information about the plant, including extensions.
     */
    function getPlantInfoExtended(
        uint256 id
    ) public view returns (IGame.PlantFull memory) {
        return _getPlantInfo(id, true);
    }

    /**
     * @dev Returns detailed information about multiple plants.
     * @param _nftIds The IDs of the plants.
     * @return An array of detailed information about the plants.
     */
    function getPlantsInfo(
        uint256[] memory _nftIds
    ) public view returns (IGame.PlantFull[] memory) {
        return _getPlantsInfoExtended(_nftIds, false);
    }

    /**
     * @dev Returns detailed information about plants owned by a specific address.
     * @param _owner The address of the owner.
     * @return An array of detailed information about the plants owned by the address.
     */
    function getPlantsByOwner(
        address _owner
    ) public view returns (IGame.PlantFull[] memory) {
        return _getPlantsByOwnerExtended(_owner, false);
    }

    /**
     * @dev Returns detailed information about multiple plants, including extensions.
     * @param _nftIds The IDs of the plants.
     * @return An array of detailed information about the plants, including extensions.
     */
    function getPlantsInfoExtended(
        uint256[] memory _nftIds
    ) public view returns (IGame.PlantFull[] memory) {
        return _getPlantsInfoExtended(_nftIds, true);
    }

    /**
     * @dev Returns detailed information about multiple plants, with an option to include extensions.
     * Plants with status BURNED are excluded.
     * @param _nftIds The IDs of the plants.
     * @param withExtensions Whether to include extensions in the plant information.
     * @return An array of detailed information about the plants.
     */
    function _getPlantsInfoExtended(
        uint256[] memory _nftIds,
        bool withExtensions
    ) private view returns (IGame.PlantFull[] memory) {
        IGame.PlantFull[] memory plants = new IGame.PlantFull[](_nftIds.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < _nftIds.length; i++) {
            IGame.PlantFull memory plant = _getPlantInfo(_nftIds[i], withExtensions);
            if (plant.status != IGame.Status.BURNED) {
                // Skip burned plants
                plants[validCount] = plant;
                validCount++;
            }
        }

        // Resize the array to the valid count
        assembly {
            mstore(plants, validCount)
        }

        return plants;
    }

    /**
     * @dev Returns detailed information about plants owned by a specific address, including extensions.
     * @param _owner The address of the owner.
     * @return An array of detailed information about the plants owned by the address, including extensions.
     */
    function getPlantsByOwnerExtended(
        address _owner
    ) public view returns (IGame.PlantFull[] memory) {
        return _getPlantsByOwnerExtended(_owner, true);
    }

    /**
     * @dev Returns detailed information about plants owned by a specific address, with an option to include extensions.
     * Plants with status BURNED are excluded.
     * @param _owner The address of the owner.
     * @param withExtensions Whether to include extensions in the plant information.
     * @return An array of detailed information about the plants owned by the address.
     */
    function _getPlantsByOwnerExtended(
        address _owner,
        bool withExtensions
    ) private view returns (IGame.PlantFull[] memory) {
        uint32[] memory ids = _s().idsByOwner[_owner];
        IGame.PlantFull[] memory plants = new IGame.PlantFull[](ids.length);
        uint256 validCount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            IGame.PlantFull memory plant = _getPlantInfo(ids[i], withExtensions);
            if (plant.status != IGame.Status.BURNED) {
                // Skip burned plants
                plants[validCount] = plant;
                validCount++;
            }
        }

        // Resize the array to the valid count
        assembly {
            mstore(plants, validCount)
        }

        return plants;
    }

    /**
     * @dev Returns detailed information about plants owned by a specific address.
     * @param _owner The address of the owner.
     * @return An array of detailed information about the plants owned by the address.
     */
    function _getPlantsByOwner(
        address _owner
    ) public view returns (IGame.PlantFull[] memory) {
        uint32[] storage ids = _s().idsByOwner[_owner];
        IGame.PlantFull[] memory plants = new IGame.PlantFull[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            plants[i] = _getPlantInfo(ids[i], true);
        }
        return plants;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Adds a token ID to the owner's list of tokens.
     * @param tokenId The ID of the token to be added.
     * @param owner The address of the owner.
     */
    function _addTokenIdToOwner(uint32 tokenId, address owner) internal {
        _s().ownerIndexById[tokenId] = uint32(_s().idsByOwner[owner].length);
        _s().idsByOwner[owner].push(tokenId);
    }

    /**
     * @dev Mints a new NFT to a specified address.
     * @param strain The strain of the NFT to be minted.
     * @param to The address to which the NFT will be minted.
     */
    function _mintTo(uint256 strain, address to) internal nonReentrant {
        require(_s().mintIsActive, "Mint is closed");
        require(_s().strainIsActive[strain], "Strain is not active");
        require(
            _s().strainTotalMinted[strain] < _s().strainMaxSupply[strain],
            "Strain supply exceeded"
        );

        _tokenBurnAndRedistribute(to, _s().mintPriceByStrain[strain]);
        uint256 tokenId = _totalMinted();

        uint256 _strainInitialTOD = _s().strainInitialTOD[strain] == 0
            ? 1 days
            : _s().strainInitialTOD[strain];

        IGame.Plant memory plant = IGame.Plant({
            id: tokenId,
            name: "",
            timeUntilStarving: block.timestamp + _strainInitialTOD,
            score: 0,
            timePlantBorn: block.timestamp,
            lastAttackUsed: 0,
            lastAttacked: 0,
            stars: 0,
            strain: strain
        });

        _createPlant(plant);

        _addTokenIdToOwner(uint32(tokenId), to);
        uint256 quantity = 1;
        _mint(to, quantity);
        emit Mint(to, strain, tokenId);

        _s().strainTotalMinted[strain]++;
    }

    /**
     * @dev Creates a new plant with the specified attributes.
     * @param plant The plant to be created.
     */
    function _createPlant(IGame.Plant memory plant) internal {
        _s().plantName[plant.id] = plant.name;
        _s().plantStrain[plant.id] = plant.strain;
        _s().plantTimeBorn[plant.id] = block.timestamp;
        _s().plantTimeUntilStarving[plant.id] = plant.timeUntilStarving;
        _s().plantScore[plant.id] = plant.score;
        _s().plantLastAttackUsed[plant.id] = plant.lastAttackUsed;
        _s().plantLastAttacked[plant.id] = plant.lastAttacked;
        _s().plantStars[plant.id] = plant.stars;
    }

    /**
     * @dev Burns tokens and redistributes them according to the burn percentage.
     * @param account The account from which tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function _tokenBurnAndRedistribute(
        address account,
        uint256 amount
    ) internal {
        uint256 _burnPercentage = _s().burnPercentage;

        // Calculate the burn amount based on the provided amount
        uint256 _burnAmount = amount.mulDivDown(_burnPercentage, 100);

        // Calculate the amount for revShareWallet
        uint256 _revShareAmount = amount.mulDivDown(100 - _burnPercentage, 100);

        // Burn the calculated amount of tokens
        if (_burnAmount > 0) {
            _s().token.transferFrom(account, address(0), _burnAmount);
        }

        // Transfer the calculated share of tokens to the revShareWallet
        if (_revShareAmount > 0) {
            _s().token.transferFrom(
                account,
                _s().revShareWallet,
                _revShareAmount
            );
        }
    }

    /**
     * @dev Removes a token ID from the owner's list of tokens.
     * @param tokenId The ID of the token to be removed.
     * @param owner The address of the owner.
     * @return bool indicating success.
     */
    function _removeTokenIdFromOwner(
        uint32 tokenId,
        address owner
    ) internal returns (bool) {
        uint32[] storage ids = _s().idsByOwner[owner];
        uint256 balance = ids.length;

        uint32 index = _s().ownerIndexById[tokenId];
        if (ids[index] != tokenId) {
            return false;
        }
        uint32 movingId = ids[index] = ids[balance - 1];
        _s().ownerIndexById[movingId] = index;
        ids.pop();

        return true;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param startTokenId The starting ID of the token being transferred.
     * @param batchSize The size of the batch being transferred.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 batchSize
    ) internal override {
        for (uint256 i = 0; i < batchSize; i++) {
            uint256 tokenId = startTokenId + i;
            if (from == address(0)) {
                // No action taken
            } else if (to == address(0)) {
                // No action taken
            } else {
                _removeTokenIdFromOwner(uint32(tokenId), from);
                _addTokenIdToOwner(uint32(tokenId), to);
            }
        }
    }

    /**
     * @dev Returns the storage struct for the contract.
     * @return The storage struct.
     */
    function _s() internal pure returns (GameStorage.Data storage) {
        return GameStorage.data();
    }

    //    function _msgData() internal view override(ERC2771ContextConsumer, Context, Permissions) returns (bytes calldata) {
    //        return ERC2771ContextConsumer._msgData();
    //    }
    //
    //    function _msgSender() internal view override(ERC2771ContextConsumer, Context, Permissions) returns (address sender) {
    //        return ERC2771ContextConsumer._msgSender();
    //    }
    function _msgData()
        internal
        view
        override(Context /*, Permissions*/)
        returns (bytes calldata)
    {
        return Context._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context /*, Permissions*/)
        returns (address sender)
    {
        return Context._msgSender();
    }
}
