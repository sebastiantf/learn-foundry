// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/InvariantTest.sol";
import "../src/WETH9.sol";
import "./handlers/Handler.sol";

contract WETH9Invariants is Test, InvariantTest {
    WETH9 public weth;
    Handler public handler;

    function setUp() public {
        weth = new WETH9();
        handler = new Handler(weth);

        targetContract(address(handler));
    }

    /* function invariant_totalSupplyStaysZero() public {
        // totalSupply will stay at zero since fuzzer does not fuzz msg.value,
        // which is required to deposit() and increase WETH supply
        // We need a handler method to set up those conditions
        assertEq(weth.totalSupply(), 0);
    } */

    // unit test that shows its possible to deposit and mint zero amount WETH
    function test_zeroDeposit() public {
        weth.deposit{value: 0}();
        assertEq(0, weth.balanceOf(address(this)));
        assertEq(0, weth.totalSupply());
    }
}
