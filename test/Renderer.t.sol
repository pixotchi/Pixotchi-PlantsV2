// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/nft/Renderer.sol";

contract RendererTest is Test {
    Renderer public renderer;

    function setUp() public {
        renderer = new Renderer();
    }

    function testCalculateImageLevel() public {
        // Test lower bounds
        assertEq(renderer.calculateImageLevel(0), 0, "Level 0 should return image level 0");
        assertEq(renderer.calculateImageLevel(1), 0, "Level 1 should return image level 0");
        assertEq(renderer.calculateImageLevel(5), 0, "Level 5 should return image level 0");

        // Test level transitions
        assertEq(renderer.calculateImageLevel(6), 1, "Level 6 should return image level 1");
        assertEq(renderer.calculateImageLevel(10), 1, "Level 10 should return image level 1");
        assertEq(renderer.calculateImageLevel(11), 2, "Level 11 should return image level 2");

        // Test mid-range levels
        assertEq(renderer.calculateImageLevel(50), 9, "Level 50 should return image level 9");
        assertEq(renderer.calculateImageLevel(51), 10, "Level 51 should return image level 10");

        // Test upper bounds
        assertEq(renderer.calculateImageLevel(110), 21, "Level 110 should return image level 21");
        assertEq(renderer.calculateImageLevel(111), 22, "Level 111 should return image level 22");
        assertEq(renderer.calculateImageLevel(115), 22, "Level 115 should return image level 22");

        // Test beyond max level
        assertEq(renderer.calculateImageLevel(116), 22, "Level 116 should return max image level 22");
        assertEq(renderer.calculateImageLevel(1000), 22, "Level 1000 should return max image level 22");
    }

    function testExample() public {
        assertTrue(true);
    }
}
