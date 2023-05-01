// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/WETH9.sol";

contract Handler is Test {
    WETH9 public weth;

    constructor(WETH9 _weth) {
        weth = _weth;
    }

    function deposit(uint256 _amount) public {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        weth.deposit{value: _amount}();
    }
}
