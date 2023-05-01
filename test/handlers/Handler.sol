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

        // send required ETH to fuzzed callers
        _pay(msg.sender, _amount);

        // pass on fuzzed callers
        vm.prank(msg.sender);
        weth.deposit{value: _amount}();

        ghost_depositSum += _amount;
    }

    function withdraw(uint256 _amount) public {
        // bound to available WETH balance
        _amount = bound(_amount, 0, weth.balanceOf(msg.sender));

        // pass on fuzzed callers
        vm.startPrank(msg.sender); // startPrank because two actions to be pranked
        weth.withdraw(_amount);

        // send withdrawn ETH back to Handler from fuzzed callers
        _pay(address(this), _amount);

        vm.stopPrank();

        ghost_withdrawSum += _amount;
    }

    function transferETHToDeposit(uint256 _amount) public {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        // send required ETH to fuzzed callers
        _pay(msg.sender, _amount);

        // pass on fuzzed callers
        vm.prank(msg.sender);
        (bool success, ) = address(weth).call{value: _amount}("");
        require(success);

        ghost_depositSum += _amount;
    }

    // required to receive ether after withdraw()
    receive() external payable {}

    function _pay(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }
}
