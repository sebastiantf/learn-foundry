check:
	git apply "bugs/$(bug)Bug.patch" && forge build && forge test --match-contract WETH9Invariants -vv

clean:
	git checkout src/WETH9.sol