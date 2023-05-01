// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/WETH9.sol";

contract Handler {
    WETH9 public weth;

    constructor(WETH9 _weth) {
        weth = _weth;
    }

    function deposit(uint256 _amount) public {
        weth.deposit{value: _amount}();
    }
}
