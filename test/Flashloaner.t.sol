// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "../src/Flashloaner.sol";

contract FlashloanerTest is Test {
    Flashloaner public flashloaner;
    MockERC20 public mockERC20;

    address alice = address(0x1337);
    address bob = address(0x133702);

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "FlashloanerTest");

        mockERC20 = new MockERC20("MockERC20", "MERC20", 18);
        mockERC20.mint(address(this), 1000e18);

        vm.label(address(mockERC20), "MockERC20");

        flashloaner = new Flashloaner(address(mockERC20));
    }

    function testAssertTrue() public {
        assertTrue(true);
    }
}
