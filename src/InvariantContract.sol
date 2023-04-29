// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract InvariantContract {
    uint256 public val1;
    uint256 public val2;
    uint256 public val3;

    /// Add equal amount to val1 & val3
    /// @param amount amount to add
    function increment1(uint256 amount) public {
        val1 += amount;
        val3 += amount;
    }

    /// Add equal amount to val2 & val3
    /// @param amount amount to add
    function increment2(uint256 amount) public {
        val2 += amount;
        val3 += amount;
    }
}
