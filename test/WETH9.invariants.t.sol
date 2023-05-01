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

        // Limit selectors to avoid unnecessary calls to irrelevant Handler methods, reducing reverts
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = Handler.deposit.selector;
        selectors[1] = Handler.withdraw.selector;
        selectors[2] = Handler.transferETHToDeposit.selector;

        targetContract(address(handler));
        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
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

    function invariant_conservationOfETH() public {
        // totalSupply of WETH and Handler's ETH balance should equal total ETH_SUPPLY
        assertEq(
            weth.totalSupply() + address(handler).balance,
            handler.ETH_SUPPLY()
        );
    }

    function invariant_solvency() public {
        // WETH9 should have enough ETH balance to handle all withdrawals
        assertEq(
            address(weth).balance,
            handler.ghost_depositSum() - handler.ghost_withdrawSum()
        );
    }

    function invariant_solvencyBalanceSum() public {
        // WETH9 should have enough ETH balance to handle all withdrawals

        // find sum of all balances of all actors
        uint256 balanceSum = handler.reduceActors(0, this.sumBalance);

        assertEq(address(weth).balance, balanceSum);
    }

    function invariant_individualBalancesLeTotalSupply() public {
        // balances of individual actors should be less than or equal total supply
        handler.forEachActors(this.assertIndividualBalance);
    }

    function sumBalance(
        uint256 acc,
        address addr
    ) external view returns (uint256) {
        return acc + weth.balanceOf(addr);
    }

    function assertIndividualBalance(address addr) external {
        assertLe(weth.balanceOf(addr), weth.totalSupply());
    }
}
