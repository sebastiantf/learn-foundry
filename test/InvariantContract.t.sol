// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/InvariantContract.sol";

contract InvariantContractTest is Test {
    InvariantContract public invariantContract;

    function setUp() public {
        invariantContract = new InvariantContract();
    }

    function invariant_val3EqualsVal1PlusVal2() public {
        // direct assertion
        assertEq(
            invariantContract.val1() + invariantContract.val2(),
            invariantContract.val3()
        );
    }

    function invariant_val1PlusVal2GeVal1() public {
        // direct assertion
        assertGe(
            invariantContract.val1() + invariantContract.val2(),
            invariantContract.val1()
        );
    }

    function invariant_val1PlusVal2GeVal2() public {
        // direct assertion
        assertGe(
            invariantContract.val1() + invariantContract.val2(),
            invariantContract.val2()
        );
    }
}
