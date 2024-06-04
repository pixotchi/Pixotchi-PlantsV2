// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


//import "../../lib/contracts/lib/solady/src/utils/SafeTransferLib.sol";
//import "../utils/FixedPointMathLib.sol";
//import "../../lib/contracts/lib/openzeppelin-contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";


/**
 * @author  7118.eth
 */
library ArcadeLibrary {
//
//    using SafeTransferLib for address payable;
//    using FixedPointMathLib for uint256;
//    using SafeMathUpgradeable for uint256;
//
//
//    //  function to generate a pseudo-random number based on several blockchain parameters.
//    function random(
//        uint256 seed,
//        uint256 min,
//        uint256 max
//    ) public view returns (uint) {
//        uint randomHash = uint(
//            keccak256(
//                abi.encodePacked(
//                    blockhash(block.number - 1),
//                    block.prevrandao,
//                    seed,
//                    block.number
//                )
//            )
//        );
//        return min + (randomHash % (max - min + 1));
//    }
//
//    // Secondary  function for random number generation.
//    function random2(
//        uint256 seed,
//        uint256 min,
//        uint256 max
//    ) public view returns (uint) {
//        uint randomHash = uint(
//            keccak256(
//                abi.encodePacked(
//                    seed,
//                    block.prevrandao,
//                    block.timestamp,
//                    msg.sender
//                )
//            )
//        );
//        return min + (randomHash % (max - min + 1));
//    }
//
//    //uint256
//    function random3(
//        uint256 seed,
//        uint256 min,
//        uint256 max
//    ) public view returns (uint256) {
//        uint256 randomHash = uint256(
//            keccak256(
//                abi.encodePacked(
//                    blockhash(block.number - 1),
//                    block.prevrandao,
//                    seed,
//                    block.number
//                )
//            )
//        );
//        return min + (randomHash % (max - min + 1));
//    }
//
//    //uint256
//
//    function random4(
//        uint256 seed,
//        uint256 min,
//        uint256 max
//    ) public view returns (uint256) {
//        uint256 randomHash = uint256(
//            keccak256(
//                abi.encodePacked(
//                    seed,
//                    block.prevrandao,
//                    block.timestamp,
//                    msg.sender
//                )
//            )
//        );
//        return min + (randomHash % (max - min + 1));
//    }
//
//    //no input
//    function random5() public view returns (uint256) {
//        uint256 randomHash = uint256(
//            keccak256(
//                abi.encodePacked(
//                    tx.origin,
//                    blockhash(block.number - 1),
//                    block.timestamp
//                )
//            )
//        );
//        return randomHash;
//    }
//
//    function random6(uint256 min, uint256 max) public view returns (uint256) {
//        uint256 randomHash = random5();
//        uint256 returnValue = min + (randomHash % (max - min + 1));
//        return returnValue;
//    }
//

}
