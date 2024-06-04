// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// ====== Internal imports ======
import "../game/GameStorage.sol";
import "../IPixotchi.sol";

// ====== External imports ======
import "../utils/FixedPointMathLib.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../utils/PixotchiExtensionPermission.sol";


contract GardenLogic is
IGarden,
ReentrancyGuard,
Initializable,
PixotchiExtensionPermission
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


    /*///////////////////////////////////////////////////////////////
                            Constructor logic
    //////////////////////////////////////////////////////////////*/


    function initializeGardenLogic() public reinitializer(4) {
        uint256 etherConversion = 1 ether;
        uint256 pointsConversion = 1e12;
        uint256 timeConversion = 1 hours;

        _createItem("Sunlight", 4 * etherConversion, 50 * pointsConversion, 0);
        _createItem("Water", 6 * etherConversion, 0, 6 * timeConversion);
        _createItem("Fertilizer", 10 * etherConversion, 75 * pointsConversion, 0);
        _createItem("Pollinator", 8 * etherConversion, 0, 8 * timeConversion);
        _createItem("Magic Soil", 12 * etherConversion, 90 * pointsConversion, 0);
        _createItem("Dream Dew", 15 * etherConversion, 50 * pointsConversion, 12 * timeConversion);
    }

    function getGardenItem(uint256 itemId)
        public
        view
        returns (IGarden.FullItem memory)
    {
        require(itemExists(itemId), "This item doesn't exist");

        GameStorage.Data storage s = _s();
        return IGarden.FullItem({
            id: itemId,
            name: s.itemName[itemId],
            price: s.itemPrice[itemId],
            points: s.itemPoints[itemId],
            timeExtension: s.itemTimeExtension[itemId]
        });
    }

    function getAllGardenItem()
    public
    view

    returns (IGarden.FullItem[] memory)
    {
        GameStorage.Data storage s = _s();
        uint256 itemCount = s._itemIds;
        IGarden.FullItem[] memory items = new IGarden.FullItem[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            items[i] = IGarden.FullItem({
                id: i,
                name: s.itemName[i],
                price: s.itemPrice[i],
                points: s.itemPoints[i],
                timeExtension: s.itemTimeExtension[i]
            });
        }

        return items;
    }

    function buyAccessory(
        uint256 nftId,
        uint256 itemId
    ) external nonReentrant {
        require(itemExists(itemId), "This item doesn't exist");
        require(IGame(address(this)).isPlantAlive(nftId), "plant dead"); //no revives
        require((IERC721A(address(this)).ownerOf(nftId) == msg.sender)); // equals isApprovedFn

        uint256 amount = _s().itemPrice[itemId];

        // recalculate time until starving
        _s().plantTimeUntilStarving[nftId] += _s().itemTimeExtension[itemId];

        if (_s().plantScore[nftId] > 0) {
            _s().ethOwed[nftId] = IGame(address(this)).pendingEth(nftId);
        }

        if (!IGame(address(this)).isPlantAlive(nftId)) {
            _s().plantScore[nftId] = _s().itemPoints[itemId];
        } else {
            _s().plantScore[nftId] += _s().itemPoints[itemId];
        }

        _s().plantRewardDebt[nftId] = _s().plantScore[nftId].mulDivDown(
            _s().ethAccPerShare,
            _s().PRECISION
        );

        _s().totalScores += _s().itemPoints[itemId];


        _s().guardDisarmed = true;
        INFT(address(this)).tokenBurnAndRedistribute(msg.sender, amount);
        _s().guardDisarmed = false;

        emit ItemConsumed(nftId, msg.sender, itemId);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    function itemExists(uint256 itemId) public view returns (bool) {
        if (bytes(_s().itemName[itemId]).length > 0) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev Returns the storage.
    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

function createItem(
    string memory name,
    uint256 price,
    uint256 points,
    uint256 timeExtension
) external onlyAdminRole {
    _createItem(name, price, points, timeExtension);
}

function createItems(
    FullItem[] calldata items
) external onlyAdminRole {
    _createItems(items);
}

function editItem(
    uint256 _id,
    uint256 _price,
    uint256 _points,
    string calldata _name,
    uint256 _timeExtension
) external onlyAdminRole {
    _editItem(_id, _price, _points, _name, _timeExtension);
}

function editGardenItems(
    FullItem[] calldata updates
) external onlyAdminRole {
    _editItems(updates);
}

function _createItem(
    string memory name,
    uint256 price,
    uint256 points,
    uint256 timeExtension
) internal {
    uint256 newItemId = _s()._itemIds;
    _s().itemName[newItemId] = name;
    _s().itemPrice[newItemId] = price;
    _s().itemPoints[newItemId] = points;
    _s().itemTimeExtension[newItemId] = timeExtension;

    _s()._itemIds++;

    emit ItemCreated(newItemId, name, price, points);
}

function _createItems(
    FullItem[] calldata items
) internal {
    for (uint i = 0; i < items.length; i++) {
        _createItem(
            items[i].name,
            items[i].price,
            items[i].points,
            items[i].timeExtension
        );
    }
}

function _editItem(
    uint256 _id,
    uint256 _price,
    uint256 _points,
    string calldata _name,
    uint256 _timeExtension
) internal {
    _s().itemPrice[_id] = _price;
    _s().itemPoints[_id] = _points;
    _s().itemName[_id] = _name;
    _s().itemTimeExtension[_id] = _timeExtension;
}

function _editItems(
    FullItem[] calldata updates
) internal {
    for (uint i = 0; i < updates.length; i++) {
        _editItem(
            updates[i].id,
            updates[i].price,
            updates[i].points,
            updates[i].name,
            updates[i].timeExtension
        );
    }
}


    //    function _msgData() internal view override(Permissions, Context) returns (bytes calldata) {
    //        return Context._msgData();
    //    }
    //
    //    function _msgSender() internal view override(Permissions, Context) returns (address sender) {
    //        return Context._msgSender();
    //    }
}
