// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/WETH9.sol";

struct AddressSet {
    address[] addresses;
    mapping(address => bool) saved;
}

library LibAddressSet {
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

contract Handler is Test {
    using LibAddressSet for AddressSet;

    WETH9 public weth;

    uint256 public constant ETH_SUPPLY = 21_000_000;

    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;

    AddressSet internal _actors;

    address internal currentActor;

    modifier createActor() {
        _actors.add(msg.sender);
        currentActor = msg.sender;
        _;
    }

    constructor(WETH9 _weth) {
        weth = _weth;
        deal(address(this), ETH_SUPPLY);
        // now the totalSupply wont stay at zero, thus breaking invariant_totalSupplyStaysZero
    }

    function deposit(uint256 _amount) public createActor {
        // bound to available balance to avoid reverts
        _amount = bound(_amount, 0, address(this).balance);

        // send required ETH to fuzzed callers
        _pay(currentActor, _amount);

        // pass on fuzzed callers
        vm.prank(currentActor);
        weth.deposit{value: _amount}();

        ghost_depositSum += _amount;
    }

    function withdraw(uint256 _amount) public createActor {
        // bound to available WETH balance
        _amount = bound(_amount, 0, weth.balanceOf(currentActor));

        // pass on fuzzed callers
        vm.startPrank(currentActor); // startPrank because two actions to be pranked
        weth.withdraw(_amount);

        // send withdrawn ETH back to Handler from fuzzed callers
        _pay(address(this), _amount);

        vm.stopPrank();

        ghost_withdrawSum += _amount;
    }

    function transferETHToDeposit(uint256 _amount) public createActor {
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
