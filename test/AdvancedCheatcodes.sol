// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "../src/Flashloaner.sol";

contract B {
    uint256 public stateVar;
}

contract FlashloanerTest is Test {
    using stdStorage for StdStorage;

    B b;

    function setUp() public {
        b = new B();
    }

    function test_stdStorage() public {
        assertEq(b.stateVar(), 0);

        stdstore.target(address(b)).sig(b.stateVar.selector).checked_write(100);

        assertEq(b.stateVar(), 100);
    }
}
