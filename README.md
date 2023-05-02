# learn-foundry

- [Intro to Foundry | The FASTEST Smart Contract Framework](https://www.youtube.com/watch?v=fNMfMxGxeag)
- [How to Foundry with Brock Elmore](https://www.youtube.com/watch?v=Rp_V7bYiTCM)
- [How to Foundry 2.0: Brock Elmore](https://www.youtube.com/watch?v=EHrvD5c93JU)
- [Foundry Book](https://book.getfoundry.sh)
- [Invariant Testing - Foundry Book](https://book.getfoundry.sh/forge/invariant-testing)
- [Invariant Testing WETH With Foundry](https://mirror.xyz/horsefacts.eth/Jex2YVaO65dda6zEyfM_-DXlXhOWCAoSpOx5PLocYgw)

## Useful commands

#### Gas snapshot

```sh
forge snapshot
forge snapshot --diff
forge snapshot --check
```

#### Include extra outputs from compiler

Generates assembly and ir output files in the out folder

```sh
forge build --extra-output evm.assembly ir --extra-output-files evm.assembly ir
```

#### Inspect IR

```sh
forge inspect Counter ir > Counter.ir
```

#### Run test in debugger

```sh
forge debug ./test/Counter.t.sol -s "testIncrement()" --tc CounterTest
```

#### Run live transaction in debugger

```sh
cast run <tx_hash> --debug --rpc-url <rpc_url>
```
