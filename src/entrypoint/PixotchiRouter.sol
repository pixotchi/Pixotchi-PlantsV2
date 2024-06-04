// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/// @author pixotchi

//            $$\                       $$\               $$\       $$\
//            \__|                      $$ |              $$ |      \__|
//   $$$$$$\  $$\ $$\   $$\  $$$$$$\  $$$$$$\    $$$$$$$\ $$$$$$$\  $$\
//  $$  __$$\ $$ |\$$\ $$  |$$  __$$\ \_$$  _|  $$  _____|$$  __$$\ $$ |
//  $$ /  $$ |$$ | \$$$$  / $$ /  $$ |  $$ |    $$ /      $$ |  $$ |$$ |
//  $$ |  $$ |$$ | $$  $$<  $$ |  $$ |  $$ |$$\ $$ |      $$ |  $$ |$$ |
//  $$$$$$$  |$$ |$$  /\$$\ \$$$$$$  |  \$$$$  |\$$$$$$$\ $$ |  $$ |$$ |
//  $$  ____/ \__|\__/  \__| \______/    \____/  \_______|\__|  \__|\__|
//  $$ |
//  $$ |
//  \__|

// ====== Special thanks to ======

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

// ====== and to ======


//                     |"|                                       |"|      #                 # #   ___         _     _       _     _       |               ___
//       vvv          _|_|_       `  _ ,  '     `  _ ,  '       _|_|_     #=ooO=========Ooo=# #  <_*_>      o' \,=./ `o   o' \,=./ `o     |.===.         /\#/\
//      (0~0)         (o o)      -  (o)o)  -   -  (o)o)  -      (o o)     #  \\  (o o)  //  # #  (o o)         (o o)         (o o)        {}o o{}       /(o o)\
//  ooO--(_)--Ooo-ooO--(_)--Ooo--ooO'(_)--Ooo--ooO'(_)--Ooo-ooO--(_)--Ooo---------(_)---------8---(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-ooO--(_)--Ooo-


//   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄
//  ▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
//  ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌ ▀▀▀▀█░█▀▀▀▀ ▐░▌░▌     ▐░▌
//  ▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌▐░▌    ▐░▌
//  ▐░▌       ▐░▌▐░▌ ▐░▌   ▐░▌▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌     ▐░▌     ▐░▌ ▐░▌   ▐░▌
//  ▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░▌  ▐░▌  ▐░▌
//  ▐░▌       ▐░▌▐░▌   ▐░▌ ▐░▌▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌     ▐░▌     ▐░▌   ▐░▌ ▐░▌
//  ▐░▌       ▐░▌▐░▌    ▐░▌▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌     ▐░▌     ▐░▌    ▐░▌▐░▌
//  ▐░█▄▄▄▄▄▄▄█░▌▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌       ▐░▌ ▄▄▄▄█░█▄▄▄▄ ▐░▌     ▐░▐░▌
//  ▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
//   ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀
//


//   ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄       ▄▄  ▄▄       ▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄
//  ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░▌     ▐░░▌▐░░▌     ▐░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
//  ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░▌░▌   ▐░▐░▌▐░▌░▌   ▐░▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌
//  ▐░▌          ▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌          ▐░▌       ▐░▌
//  ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌ ▐░▐░▌ ▐░▌▐░▌ ▐░▐░▌ ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌
//  ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
//   ▀▀▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░▌   ▀   ▐░▌▐░▌   ▀   ▐░▌▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀█░█▀▀
//            ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌          ▐░▌     ▐░▌
//   ▄▄▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░▌      ▐░▌
//  ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌
//   ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀
//


import {BaseRouter, IRouter, IRouterState} from "../../lib/dynamic-contracts/src/presets/BaseRouter.sol";
import "../../lib/contracts/contracts/extension/upgradeable/PermissionsEnumerable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/Initializable.sol";
import "../../lib/contracts/contracts/extension/upgradeable/init/ReentrancyGuardInit.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ReentrancyGuard.sol";
import "../../lib/contracts/contracts/extension/upgradeable/ERC2771ContextUpgradeable.sol";
import "../utils/FixedPointMathLib.sol";
import "../game/GameStorage.sol";


contract PixotchiRouter is
Initializable,
BaseRouter,
PermissionsEnumerable,
ReentrancyGuardInit,
ReentrancyGuard,
ERC2771ContextUpgradeable
{
    /// @dev Only EXTENSION_ROLE holders can perform upgrades.
    bytes32 private constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");

    bytes32 private constant MODULE_TYPE = bytes32("PixotchiRouter");
    uint256 private constant VERSION = 1;

    /// @dev We accept constructor params as a struct to avoid `Stack too deep` errors.
    struct SimpleRouterConstructorParams {
        Extension[] extensions;
    }

    constructor(
        SimpleRouterConstructorParams memory _simpleRouterV3Params
    ) BaseRouter(_simpleRouterV3Params.extensions)  {
        __BaseRouter_init();
    }

    receive() external payable {
        GameStorage.Data storage _s = GameStorage.data();
        _s.ethAccPerShare += FixedPointMathLib.mulDivDown(msg.value, _s.PRECISION, _s.totalScores);
    }

    /// @dev Initializes the contract, like a constructor.
    function initializeRouter(
    ) external initializer {
        __ReentrancyGuard_init();
        address _defaultAdmin = 0x44e156CBb4506cee55A96b45D10A77806E012469;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(EXTENSION_ROLE, _defaultAdmin);
        _setRoleAdmin(EXTENSION_ROLE, EXTENSION_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                        Overridable Permissions
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[_role][_account];
    }

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ROLE, msg.sender);
    }

    function _msgSender()
    internal
    view
    override(ERC2771ContextUpgradeable, Permissions)
    returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, Permissions)
    returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }


}
