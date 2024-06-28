// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// Internal imports
import "../game/GameStorage.sol";
import "../IPixotchi.sol";
//import "../nft/NFTLogicDelegations.sol";
import "../utils/PixotchiExtensionPermission.sol";
import "./ShopStorage.sol";

// External imports
//import * as FixedPointMathLib from "../utils/FixedPointMathLib.sol";
import { PermissionsEnumerable } from "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import { ReentrancyGuard } from "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import { Initializable } from "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import * as IERC721A from "../../lib/contracts/contracts/eip/interface/IERC721A.sol";

/// @title ShopLogic Contract
/// @notice This contract handles the logic for the shop in the game.
/// @dev Implements the IShop interface and uses various imported libraries and contracts.
contract ShopLogic is
IShop,
ReentrancyGuard,
Initializable,
PixotchiExtensionPermission
{

    /// @notice Reinitializes the ShopLogic contract.
    /// @dev This function is called to reinitialize the contract with new settings.
    function reinitializer_8_ShopLogic() public reinitializer(8) {
        _shopCreateFence();
        _sS().shopItemCounter = 1;
    }

    /// @notice Creates a Fence item in the shop.
    /// @dev This function sets up the initial parameters for the Fence item.
    function _shopCreateFence() private {
        uint256 itemId = 0;
        string memory itemName = "Fence";
        uint256 itemPrice = 50 * 10**18;
        uint256 itemExpireTime = 0; // 0 for no expiration
        uint256 itemMaxSupply = 0; // 0 for unlimited supply
        uint256 itemEffectTime = 2 days;

        _shopModifyItem(itemId, itemName, itemPrice, itemExpireTime, itemMaxSupply, itemEffectTime);
    }

    /// @notice Modifies an existing shop item.
    /// @param itemId The ID of the item.
    /// @param name The name of the item.
    /// @param price The price of the item.
    /// @param expireTime The expiration time of the item.
    /// @param maxSupply The maximum supply of the item (0 for unlimited).
    /// @param effectTime The effect time of the item.
    function shopModifyItem(uint256 itemId, string memory name, uint256 price, uint256 expireTime, uint256 maxSupply, uint256 effectTime) external onlyAdminRole {
        _shopModifyItem(itemId, name, price, expireTime, maxSupply, effectTime);
    }

    /// @notice Modifies an existing shop item.
    /// @param itemId The ID of the item.
    /// @param name The name of the item.
    /// @param price The price of the item.
    /// @param expireTime The expiration time of the item.
    /// @param maxSupply The maximum supply of the item (0 for unlimited).
    /// @param effectTime The effect time of the item.
    function _shopModifyItem(
        uint256 itemId,
        string memory name,
        uint256 price,
        uint256 expireTime,
        uint256 maxSupply,
        uint256 effectTime
    ) private {
        _sS().shopItemName[itemId] = name;
        _sS().shopItemPrice[itemId] = price;
        _sS().shopItemExpireTime[itemId] = expireTime;
        _sS().shopItemIsActive[itemId] = true;
        _sS().shopItemTotalConsumed[itemId] = 0;
        _sS().shopItemMaxSupply[itemId] = maxSupply; // 0 = Unlimited supply
        _sS().shopItemEffectTime[itemId] = effectTime;

        emit ShopItemCreated(itemId, name, price, expireTime);
    }

    /// @notice Checks if a shop item exists.
    /// @param itemId The ID of the item.
    /// @return bool True if the item exists, false otherwise.
    function shopDoesItemExist(uint256 itemId) public view returns (bool) {
        return bytes(_sS().shopItemName[itemId]).length > 0;
    }

    /// @notice Gets all shop items.
    /// @return ShopItem[] An array of all shop items.
    function shopGetAllItems() public view returns (ShopItem[] memory) {
        uint256 itemCount = _sS().shopItemCounter;
        ShopItem[] memory items = new ShopItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            items[i] = ShopItem({
                id: i,
                name: _sS().shopItemName[i],
                price: _sS().shopItemPrice[i],
                effectTime: _sS().shopItemEffectTime[i]
            });
        }
        return items;
    }

    /// @notice Gets the purchased shop items for a specific NFT.
    /// @dev This function retrieves all the shop items that have been purchased by a specific NFT.
    /// It returns an array of `ShopItemOwned` structs, each containing details about the item.
    /// @param nftId The ID of the NFT for which to retrieve purchased items.
    /// @return ShopItemOwned[] An array of owned shop items, each containing:
    /// - `id`: The ID of the item.
    /// - `name`: The name of the item.
    /// - `effectUntil`: The timestamp until which the item's effect is active.
    /// - `effectIsOngoingActive`: A boolean indicating if the item's effect is still ongoing.
    function shopGetPurchasedItems(uint256 nftId) public view returns (ShopItemOwned[] memory) {
        ShopItemOwned[] memory ownedItems = new ShopItemOwned[](1);
        ownedItems[0] = ShopItemOwned({
            id: 0,
            name: _sS().shopItemName[0],
            effectUntil: _sS().shop_0_Fence_EffectUntil[nftId],
            effectIsOngoingActive: shopIsEffectOngoing(nftId, 0)
        });
        return ownedItems;
    }

    /// @notice Checks if the effect of a shop item is still ongoing for an NFT.
    /// @param nftId The ID of the NFT.
    /// @param itemId The ID of the item.
    /// @return bool True if the effect is still ongoing, false otherwise.
    function shopIsEffectOngoing(uint256 nftId, uint256 itemId) public view returns (bool) {
        if (itemId == 0) {
            return block.timestamp <= _sS().shop_0_Fence_EffectUntil[nftId];
        }
        // Add more conditions here for different itemIds
        // Example:
        // if (itemId == 1) {
        //     return block.timestamp <= _sS().shop_1_SomeItem_EffectUntil[nftId];
        // }
        return false;
    }

    /// @notice Buys a shop item.
    /// @param nftId The ID of the NFT.
    /// @param itemId The ID of the item to buy.
    function shopBuyItem(uint256 nftId, uint256 itemId) external nonReentrant {
        require(shopDoesItemExist(itemId), "This item doesn't exist");
        require(IGame(address(this)).isPlantAlive(nftId), "Plant is dead");
        require(IERC721A.IERC721A(address(this)).ownerOf(nftId) == msg.sender, "Not the owner");

        uint256 amount = _sS().shopItemPrice[itemId];

        // Check if the item is still active and not expired
        require(_sS().shopItemIsActive[itemId], "Item is not active");
        if (_sS().shopItemExpireTime[itemId] != 0) {
            require(block.timestamp <= _sS().shopItemExpireTime[itemId], "Item has expired");
        }

        // Check if the item has limited supply and if it's still available
        if (_sS().shopItemMaxSupply[itemId] > 0) {
            require(_sS().shopItemTotalConsumed[itemId] < _sS().shopItemMaxSupply[itemId], "Item is out of stock");
        }

        // Prevent repurchase if the effect is still ongoing
        require(!shopIsEffectOngoing(nftId, itemId), "Effect still ongoing");

        //NFTLogicDelegations._tokenBurnAndRedistribute(address(this), msg.sender, amount);
        _tokenBurnAndRedistribute(msg.sender, amount);

        // Increment the total consumed count for the item
        _sS().shopItemTotalConsumed[itemId]++;

        // Apply the item's effect
        _shopApplyItemEffect(nftId, itemId);

        emit ShopItemPurchased(nftId, msg.sender, itemId);
    }


    /// @notice Burns a portion of the tokens and redistributes the rest.
    /// @param account The address from which tokens will be burned and redistributed.
    /// @param amount The total amount of tokens to be processed.
    function _tokenBurnAndRedistribute(address account, uint256 amount) internal {
        uint256 _burnPercentage = _sG().burnPercentage;

        // Calculate the burn amount based on the provided amount
        uint256 _burnAmount = (amount * _burnPercentage) / 100;
        // Calculate the amount for revShareWallet
        uint256 _revShareAmount = amount - _burnAmount;

        // Burn the calculated amount of tokens
        if (_burnAmount > 0) {
            _sG().token.transferFrom(account, address(0), _burnAmount);
        }

        // Transfer the calculated share of tokens to the revShareWallet
        if (_revShareAmount > 0) {
            _sG().token.transferFrom(account, _sG().revShareWallet, _revShareAmount);
        }
    }

    /// @notice Applies the effect of a shop item to an NFT.
    /// @param nftId The ID of the NFT.
    /// @param itemId The ID of the item.
    function _shopApplyItemEffect(uint256 nftId, uint256 itemId) internal {
        if (itemId == 0) {
            _sS().shop_0_Fence_EffectUntil[nftId] = block.timestamp + _sS().shopItemEffectTime[itemId];
        }
        // Add more conditions here for different itemIds
    }

    /// @dev Returns the storage.
    function _sG() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

    /// @dev Returns the storage.
    function _sS() internal pure returns (ShopStorage.Data storage data) {
        data = ShopStorage.data();
    }
}
