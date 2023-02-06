// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "../src/Flashloaner.sol";

contract TokenReceiver {
    uint256 return_amount;

    function receiveTokens(
        address tokenAddress,
        uint256 /* amount */
    ) external {
        ERC20(tokenAddress).transfer(msg.sender, return_amount);
    }
}

contract FlashloanerTest is Test, TokenReceiver {
    Flashloaner public flashloaner;
    MockERC20 public mockERC20;

    address alice = address(0x1337);
    address bob = address(0x133702);

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(address(this), "FlashloanerTest");

        mockERC20 = new MockERC20("MockERC20", "MERC20", 18);
        mockERC20.mint(address(this), 1000e18);

        vm.label(address(mockERC20), "MockERC20");

        flashloaner = new Flashloaner(address(mockERC20));

        mockERC20.approve(address(flashloaner), 100);
        flashloaner.depositTokens(100);
    }

    function test_ConstructorRevertOnZeroAddress() public {
        vm.expectRevert(Flashloaner.TokenAddressCannotBeZero.selector);
        new Flashloaner(address(0));
    }

    function test_depositTokensRevertOnZeroAmount() public {
        vm.expectRevert(Flashloaner.MustDepositOneTokenMinimum.selector);
        flashloaner.depositTokens(0);

        vm.expectRevert(Flashloaner.MustDepositOneTokenMinimum.selector);
        flashloaner.depositTokens(0);
    }

    function test_depositTokensIncreasePoolBalance() public {
        assertEq(flashloaner.poolBalance(), 100);

        mockERC20.approve(address(flashloaner), 1);
        flashloaner.depositTokens(1);

        assertEq(flashloaner.poolBalance(), 101);
        assertEq(
            mockERC20.balanceOf(address(flashloaner)),
            flashloaner.poolBalance()
        );
    }

    function test_flashloanRevertMustBorrowOneTokenMinimum() public {
        vm.expectRevert(Flashloaner.MustBorrowOneTokenMinimum.selector);
        flashloaner.flashLoan(0);
    }

    function test_flashloanRevertNotEnoughTokensInPool() public {
        vm.expectRevert(Flashloaner.NotEnoughTokensInPool.selector);
        flashloaner.flashLoan(102);
    }

    function test_flashloanRevertFlashLoanHasNotBeenPaidBack() public {
        return_amount = 0;
        vm.expectRevert(Flashloaner.FlashLoanHasNotBeenPaidBack.selector);
        flashloaner.flashLoan(1);
    }

    function test_flashloan() public {
        return_amount = 10;
        uint256 borrowAmount = 10;
        flashloaner.flashLoan(borrowAmount);

        assertEq(
            flashloaner.poolBalance(),
            100 + (return_amount - borrowAmount)
        );
        assertEq(
            mockERC20.balanceOf(address(flashloaner)),
            flashloaner.poolBalance()
        );
        assertEq(
            mockERC20.balanceOf(address(this)),
            1000e18 - 100 - (return_amount - borrowAmount)
        );
    }

    function test_updateOwner() public {
        vm.startPrank(bob);
        vm.expectRevert("!owner");
        flashloaner.updateOwner(bob);
        flashloaner.echoSender();
        vm.stopPrank();

        vm.prank(bob);
        vm.expectRevert("!owner");
        flashloaner.updateOwner(bob);
        flashloaner.echoSender();
    }

    function testFuzz_depositTokens(uint256 amount) public {
        vm.assume(amount <= mockERC20.totalSupply());
        vm.assume(amount != 0);

        uint256 beforeBalance = mockERC20.balanceOf(address(flashloaner));

        mockERC20.approve(address(flashloaner), amount);
        flashloaner.depositTokens(amount);

        assertEq(flashloaner.poolBalance(), beforeBalance + amount);
        assertEq(
            mockERC20.balanceOf(address(flashloaner)),
            flashloaner.poolBalance()
        );
    }

    function testFuzz_flashLoan(uint256 borrowAmount, uint256 _return_amount)
        public
    {
        vm.assume(borrowAmount != 0);
        vm.assume(_return_amount <= mockERC20.balanceOf(address(this)));
        vm.assume(borrowAmount <= mockERC20.balanceOf(address(flashloaner)));
        vm.assume(borrowAmount <= _return_amount);

        return_amount = _return_amount;

        flashloaner.flashLoan(borrowAmount);

        assertEq(
            flashloaner.poolBalance(),
            100 + (return_amount - borrowAmount)
        );
        assertEq(
            mockERC20.balanceOf(address(flashloaner)),
            flashloaner.poolBalance()
        );
        assertEq(
            mockERC20.balanceOf(address(this)),
            1000e18 - 100 - (return_amount - borrowAmount)
        );
    }

    function test_breakFlashloan() public {
        return_amount = 2;
        uint256 borrowAmount = 1;

        flashloaner.flashLoan(borrowAmount);

        assertEq(
            flashloaner.poolBalance(),
            100 + (return_amount - borrowAmount)
        );
        assertEq(
            mockERC20.balanceOf(address(flashloaner)),
            flashloaner.poolBalance()
        );
        assertEq(
            mockERC20.balanceOf(address(this)),
            1000e18 - 100 - (return_amount - borrowAmount)
        );
    }
}
