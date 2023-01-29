// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error TransferFailed();

contract StakeContract {
    // user => token => amount
    mapping(address => mapping(address => uint256)) balances;

    function stake(address token, uint256 amount) external returns (bool) {
        balances[msg.sender][token] = amount;
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert TransferFailed();
        return success;
    }
}
