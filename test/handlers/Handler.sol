// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/WETH9.sol";

contract Handler is Test {
    WETH9 public weth;

    uint256 public constant ETH_SUPPLY = 21_000_000;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
        // now the totalSupply wont stay at zero, thus breaking invariant_totalSupplyStaysZero
    }

    function deposit(uint256 _amount) public {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        weth.deposit{value: _amount}();

        ghost_depositSum += _amount;
    }

    function withdraw(uint256 _amount) public {
        // bound to available WETH balance
        _amount = bound(_amount, 0, weth.balanceOf(address(this)));

        weth.withdraw(_amount);

        ghost_withdrawSum += _amount;
    }

    function transferETHToDeposit(uint256 _amount) public {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        (bool success, ) = address(weth).call{value: _amount}("");
        require(success);

        ghost_depositSum += _amount;
    }

    // required to receive ether after withdraw()
    receive() external payable {}
}
