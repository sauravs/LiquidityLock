## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```


write end to end soldity test in foundry for LiquidityLockFactory contract especially testing createLock functionailtiy on polygon forked mainnet.Impersonate USDC whale on polygon mainnet to pay fee. Also create new liquidity first on uniswapV3 polygon mainnet forket by provding 1000 USDC  and mockDUGI token pair.Create mockDUGI token for that.Once the liqudity is created on NFT LP token will be generate.Lock this NFT token via createLock


forge test --match-test testCreateNormalLockFuzz