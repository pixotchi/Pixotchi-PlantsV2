// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GameStorage.sol";
import "./FenceV2Storage.sol";
import "./ShopStorage.sol";
import "./IPixotchi.sol";
import "./IToken.sol";
import "./PixotchiExtensionPermission.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IERC721A.sol";

contract FenceV2 is ReentrancyGuard, Initializable, PixotchiExtensionPermission {
    uint256 private constant ITEM_ID = 1;
    uint256 private constant MAX_DURATION_DAYS = 30;
    uint256 private constant SECONDS_PER_DAY = 1 days;

    event ShopItemCreated(uint256 id, string name, uint256 price, uint256 expireTime);
    event ShopItemPurchased(uint256 indexed nftId, address indexed buyer, uint256 indexed itemId);
    event FenceV2Extended(uint256 indexed nftId, uint256 previousExpiry, uint256 newExpiry, uint256 daysPurchased);

    function fenceV2Initialize(uint256 pricePerDay) external reinitializer(10) {
        _setPricePerDay(pricePerDay);
    }

    function fenceV2SetPricePerDay(uint256 newPricePerDay) external onlyAdminRole {
        _setPricePerDay(newPricePerDay);
    }

    function fenceV2GetConfig()
        external
        view
        returns (uint256 pricePerDay, uint256 maxDurationDays)
    {
        pricePerDay = _sFence().pricePerDay;
        maxDurationDays = MAX_DURATION_DAYS;
    }

    function fenceV2Quote(uint256 durationDays) external view returns (uint256 price) {
        price = _quote(durationDays);
    }

    function fenceV2EffectUntil(uint256 nftId) external view returns (uint256) {
        return _sFence().effectUntil[nftId];
    }

    function fenceV2IsEffectOngoing(uint256 nftId) external view returns (bool) {
        return block.timestamp <= _sFence().effectUntil[nftId];
    }

    function fenceV2HasFenceV1(uint256 nftId) external view returns (bool) {
        return _isFenceV1Active(nftId);
    }

    function fenceV2Purchase(uint256 nftId, uint256 durationDays) external nonReentrant {
        require(durationDays > 0, "Fence duration required");
        require(durationDays <= MAX_DURATION_DAYS, "Fence duration too long");
        require(IERC721A(address(this)).ownerOf(nftId) == msg.sender, "Not owner");
        require(IGame(address(this)).isPlantAlive(nftId), "Plant dead");
        uint256 v1Expiry = _sShop().shop_0_Fence_EffectUntil[nftId];
        if (block.timestamp <= v1Expiry) {
            // Allow purchase if the active fence is our mirrored Fence V2 entry.
            require(_sFence().effectUntil[nftId] == v1Expiry, "FenceV1 still active");
        }

        uint256 cost = _quote(durationDays);
        _tokenBurnAndRedistribute(msg.sender, cost);

        FenceV2Storage.Data storage data = _sFence();
        uint256 currentExpiry = data.effectUntil[nftId];
        uint256 start = currentExpiry > block.timestamp ? currentExpiry : block.timestamp;
        uint256 extension = durationDays * SECONDS_PER_DAY;
        uint256 newExpiry = start + extension;

        data.effectUntil[nftId] = newExpiry;
        data.totalDaysPurchased[nftId] += durationDays;
        data.totalPurchases += 1;

        // Mirror to legacy storage so existing GameLogic (Fence V1 guard) stays effective.
        _sShop().shop_0_Fence_EffectUntil[nftId] = newExpiry;

        emit ShopItemPurchased(nftId, msg.sender, ITEM_ID);
        emit FenceV2Extended(nftId, currentExpiry, newExpiry, durationDays);
    }

    function fenceV2GetPurchaseStats(uint256 nftId)
        external
        view
        returns (
            uint256 pricePerDay,
            uint256 activeUntil,
            uint256 totalDaysPurchased,
            bool fenceV1Active
        )
    {
        FenceV2Storage.Data storage data = _sFence();
        pricePerDay = data.pricePerDay;
        activeUntil = data.effectUntil[nftId];
        totalDaysPurchased = data.totalDaysPurchased[nftId];
        fenceV1Active = _isFenceV1Active(nftId);
    }

    function _isFenceV1Active(uint256 nftId) internal view returns (bool) {
        uint256 v1Expiry = _sShop().shop_0_Fence_EffectUntil[nftId];
        if (block.timestamp > v1Expiry) {
            return false;
        }
        // If expiry matches our own storage, it's the mirrored V2 fence, not a standalone V1.
        return _sFence().effectUntil[nftId] != v1Expiry;
    }

    function _setPricePerDay(uint256 newPricePerDay) internal {
        require(newPricePerDay > 0, "Fence price required");
        FenceV2Storage.Data storage data = _sFence();
        data.pricePerDay = newPricePerDay;
        emit ShopItemCreated(ITEM_ID, "Fence V2", newPricePerDay, 0);
    }

    function _quote(uint256 durationDays) internal view returns (uint256) {
        require(durationDays > 0, "Fence duration required");
        require(durationDays <= MAX_DURATION_DAYS, "Fence duration too long");
        uint256 pricePerDay = _sFence().pricePerDay;
        require(pricePerDay > 0, "Fence price not set");
        return pricePerDay * durationDays;
    }

    function _tokenBurnAndRedistribute(address account, uint256 amount) internal {
        GameStorage.Data storage game = _s();
        uint256 burnPercentage = game.burnPercentage;
        uint256 burnAmount = (amount * burnPercentage) / 100;
        uint256 revShareAmount = amount - burnAmount;

        if (burnAmount > 0) {
            game.token.transferFrom(account, address(0), burnAmount);
        }

        if (revShareAmount > 0) {
            game.token.transferFrom(account, game.revShareWallet, revShareAmount);
        }
    }

    function _s() internal pure returns (GameStorage.Data storage data) {
        data = GameStorage.data();
    }

    function _sFence() internal pure returns (FenceV2Storage.Data storage data) {
        data = FenceV2Storage.data();
    }

    function _sShop() internal pure returns (ShopStorage.Data storage data) {
        data = ShopStorage.data();
    }
}

