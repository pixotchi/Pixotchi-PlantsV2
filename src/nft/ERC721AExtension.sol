// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;



import "../../lib/contracts/contracts/eip/interface/IERC721A.sol";
import "../IPixotchi.sol";

library ERC721AStorage {
    /// @custom:storage-location erc7201:erc721.a.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("erc721.a.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ERC721A_STORAGE_POSITION =
    0xe2efff925b8936e8a3471e86ad87942375e24de600ddfb2b841647ce1379ed00;

    struct Data {
        // The tokenId of the next token to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
        mapping(uint256 => IERC721A.TokenOwnership) _ownerships;
        // Mapping owner address to address data
        mapping(address => IERC721A.AddressData) _addressData;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
    }

    function erc721AStorage() internal pure returns (Data storage erc721AData) {
        bytes32 position = ERC721A_STORAGE_POSITION;
        assembly {
            erc721AData.slot := position
        }
    }
}


contract ERC721AExtension is IERC721AExtension {

    /**
     * @dev Returns whether `tokenId` has been burned.
     */
    function isBurned(uint256 tokenId) public view returns (bool) {
        ERC721AStorage.Data storage data = ERC721AStorage.erc721AStorage();
        return data._ownerships[tokenId].burned;
    }

}



