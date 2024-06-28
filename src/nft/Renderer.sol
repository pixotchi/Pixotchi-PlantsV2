// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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
*/

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import"../IPixotchi.sol";

contract Renderer is IRenderer {
    uint256 private constant LEVELS_PER_IMAGE = 10;
    uint256 private constant MAX_IMAGE_LEVEL = 22;

    constructor() {
    }

    function prepareTokenURI(IGame.PlantFull calldata plant, string calldata ipfsHash/*, string calldata status, uint256 level*/) external pure returns (string memory)
    {
        string memory part2 = string(abi.encodePacked(
            '"},{"trait_type":"Time Plant Born","value":"', Strings.toString(plant.timePlantBorn),
            '"},{"trait_type":"Last Attack Used","value":"', Strings.toString(plant.lastAttackUsed),
            '"},{"trait_type":"Last Attacked","value":"', Strings.toString(plant.lastAttacked),
            '"},{"trait_type":"Level","value":"', Strings.toString(plant.level),
            '"},{"trait_type":"Status","value":"', plant.statusStr,
            '"}],"image": "'
        ));

        string memory attributes = string(abi.encodePacked(
            '{"name":"', plant.name,
            '","attributes":[{"trait_type":"ID","value":"', Strings.toString(plant.id),
            '"},{"trait_type":"Score","value":"', Strings.toString(plant.score),
            '"},{"trait_type":"Stars","value":"', Strings.toString(plant.stars),
            '"},{"trait_type":"Strain","value":"', Strings.toString(plant.strain),
            '"},{"trait_type":"Time Until Starving","value":"', Strings.toString(plant.timeUntilStarving),
            part2
        ));

        return string(abi.encodePacked(
        'data:application/json;base64,',
            Base64.encode(bytes(string(
                abi.encodePacked(
                    attributes,
                    getImageUri(plant.level, ipfsHash)
                )
            )))
        ));
    }

    /// @notice Calculates the image level based on the plant level
    /// @param _level The level of the plant
    /// @return The calculated image level
    function calculateImageLevel(uint256 _level) public pure returns (uint256) {
        if (_level == 0) return 0; // Handle potential edge case
        uint256 imageLevel = (_level - 1) / LEVELS_PER_IMAGE;
        return imageLevel > MAX_IMAGE_LEVEL ? MAX_IMAGE_LEVEL : imageLevel;
    }

    /// @notice Generates the image URI for a given level and IPFS hash
    /// @param _level The level of the plant
    /// @param ipfsHash The IPFS hash for the image
    /// @return The complete image URI
    function getImageUri(uint256 _level, string calldata ipfsHash) public pure returns (string memory) {
        uint256 imageLevel = calculateImageLevel(_level);
        return append('ipfs://', ipfsHash, '/', string(abi.encodePacked(Strings.toString(imageLevel), '.svg')), '"}');
    }

    function append(string memory a, string memory b, string memory c, string memory d, string memory e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }

}
