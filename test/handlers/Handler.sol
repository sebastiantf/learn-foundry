// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/WETH9.sol";

struct AddressSet {
    address[] addresses;
    mapping(address => bool) saved;
}

library LibAddressSet {
    function rand(
        AddressSet storage s,
        uint256 seed
    ) internal view returns (address) {
        if (s.addresses.length > 0) {
            // get random address from previously used addresses
            return s.addresses[seed % s.addresses.length];
        } else {
            return address(0x1337);
        }
    }

    function add(AddressSet storage s, address addr) internal {
        if (!s.saved[addr]) {
            s.addresses.push(addr);
            s.saved[addr] = true;
        }
    }

    function contains(
        AddressSet storage s,
        address addr
    ) internal view returns (bool) {
        return s.saved[addr];
    }

    function count(AddressSet storage s) internal view returns (uint256) {
        return s.addresses.length;
    }

    function reduce(
        AddressSet storage s,
        uint256 acc,
        function(uint256, address) external returns (uint256) func
    ) internal returns (uint256) {
        for (uint256 i; i < s.addresses.length; ++i) {
            acc = func(acc, s.addresses[i]);
        }
        return acc;
    }

    function forEach(
        AddressSet storage s,
        function(address) external func
    ) internal {
        for (uint256 i; i < s.addresses.length; ++i) {
            func(s.addresses[i]);
        }
    }
}

contract ForcePush {
    constructor(address weth) payable {
        selfdestruct(payable(weth));
    }
}

contract Handler is Test {
    using LibAddressSet for AddressSet;

    WETH9 public weth;

    uint256 public constant ETH_SUPPLY = 21_000_000;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    AddressSet internal _actors;

    address internal currentActor;

    mapping(bytes32 => uint256) public calls;

    uint256 public ghost_zeroAmountWithdraws;
    uint256 public ghost_zeroAllowanceTransferFroms;
    uint256 public ghost_forcePushETHSum;

    modifier createActor() {
        _actors.add(msg.sender);
        currentActor = msg.sender;
        _;
    }

    // can be used to reuse actors for withdraw() to avoid zeroAmountWithdraws
    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 func) {
        calls[func]++;
        _;
    }

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
        // now the totalSupply wont stay at zero, thus breaking invariant_totalSupplyStaysZero
    }

    function deposit(uint256 _amount) public createActor countCall("deposit") {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        // send required ETH to fuzzed callers
        _pay(currentActor, _amount);

        // pass on fuzzed callers
        vm.prank(currentActor);
        weth.deposit{value: _amount}();

        ghost_depositSum += _amount;
    }

    function withdraw(
        uint256 actorSeed,
        uint256 _amount
    ) public useActor(actorSeed) countCall("withdraw") {
        // bound to available WETH balance
        _amount = bound(_amount, 0, weth.balanceOf(currentActor));

        // Since during fuzzing msg.sender would almost always be new,
        // they wont have a balance. Hence _amount would mostly be zero.
        // Which is not a meaningful test. Tracking such calls here:
        if (_amount == 0) ghost_zeroAmountWithdraws++;

        // pass on fuzzed callers
        vm.startPrank(currentActor); // startPrank because two actions to be pranked
        weth.withdraw(_amount);

        // send withdrawn ETH back to Handler from fuzzed callers
        _pay(address(this), _amount);

        vm.stopPrank();

        ghost_withdrawSum += _amount;
    }

    function transferETHToDeposit(
        uint256 _amount
    ) public createActor countCall("transferETHToDeposit") {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        // send required ETH to fuzzed callers
        _pay(currentActor, _amount);

        // pass on fuzzed callers
        vm.prank(currentActor);
        (bool success, ) = address(weth).call{value: _amount}("");
        require(success);

        ghost_depositSum += _amount;
    }

    function approve(
        uint256 actorSeed,
        uint256 spenderSeed,
        uint256 _amount
    ) public useActor(actorSeed) countCall("approve") {
        // use existing actors to be reused in transferFrom
        address spender = _actors.rand(spenderSeed);

        // no need to bound _amount since its only allowance

        vm.prank(currentActor);
        weth.approve(spender, _amount);
    }

    function transfer(
        uint256 actorSeed,
        uint256 toSeed,
        uint256 _amount
    ) public useActor(actorSeed) countCall("transfer") {
        // use existing actors that may already have balance
        address to = _actors.rand(toSeed);

        _amount = bound(_amount, 0, weth.balanceOf(currentActor));

        vm.prank(currentActor);
        weth.transfer(to, _amount);
    }

    function transferFrom(
        uint256 actorSeed,
        uint256 fromSeed,
        uint256 toSeed,
        bool _approve, // fuzz prior approvals
        uint256 _amount
    ) public useActor(actorSeed) countCall("transferFrom") {
        // use existing actors that may already have approval
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);

        // from should have enough balance
        _amount = bound(_amount, 0, weth.balanceOf(from));

        if (_approve) {
            // if fuzzer sets approve, approve the currentActor
            vm.prank(from);
            weth.approve(currentActor, _amount);
        } else {
            // if not, currentActor should have enough allowance
            _amount = bound(_amount, 0, weth.allowance(currentActor, from));
        }

        // Since during fuzzing msg.sender would almost always be new,
        // they wont have any allowance. Hence _amount would mostly be zero.
        // Which is not a meaningful test. Tracking such calls here:
        if (_amount == 0) ghost_zeroAllowanceTransferFroms++;

        vm.prank(currentActor);
        weth.transferFrom(from, to, _amount);
    }

    function forcePushETH(uint256 _amount) public countCall("transferFrom") {
        _amount = bound(_amount, 0, address(this).balance);

        new ForcePush{value: _amount}(address(weth));

        ghost_forcePushETHSum += _amount;
    }

    function reduceActors(
        uint256 acc,
        function(uint256, address) external returns (uint256) func
    ) public returns (uint256) {
        return _actors.reduce(acc, func);
    }

    function forEachActors(function(address) external func) public {
        _actors.forEach(func);
    }

    function actors() public view returns (address[] memory) {
        return _actors.addresses;
    }

    // required to receive ether after withdraw()
    receive() external payable {}

    function _pay(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success);
    }
}
