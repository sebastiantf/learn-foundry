// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/StakeContract.sol";
import "./mocks/MockERC20.sol";

contract StakeContractTest is Test {
    StakeContract public stakeContract;
    MockERC20 public mockERC20;

    function setUp() public {
        stakeContract = new StakeContract();
        mockERC20 = new MockERC20("MockERC20", "MERC20");
    }

    function testStake(uint256 amount) public {
        mockERC20.approve(address(stakeContract), amount);

        bool success = stakeContract.stake(address(mockERC20), amount);
        assertTrue(success);
    }
}
