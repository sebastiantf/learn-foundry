// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/WETH9.sol";

contract WETH9Invariants is Test {
    WETH9 public weth;

    function setUp() public {
        weth = new WETH9();
    }

    function invariant_totalSupplyStaysZero() public {
        // totalSupply will stay at zero since fuzzer does not fuzz msg.value,
        // which is required to deposit() and increase WETH supply
        // We need a handler method to set up those conditions
        assertEq(weth.totalSupply(), 0);
    }
}
