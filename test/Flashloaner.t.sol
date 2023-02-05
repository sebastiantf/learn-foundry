// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Flashloaner.sol";

contract FlashloanerTest is Test {
    Flashloaner public flashloaner;

    function setUp() public {}

    function testAssertTrue() public {
        assertTrue(true);
    }
}
