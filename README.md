# ABOUT

OBX Dex is a CLOB(Central Limit Order Book) exchange, and all its data including orderbook and actions occur on chain, there's no custody of assets by central party, and you risky only a part of your assets in case of bugs or hacks.

LinkedListLib is the library contract which separates users inside a order along with PVNode and OPVSet contracts , factory contract create new Exchange contract with a pair of tokens to trade between each other, it need to be whitelisted by OBXReferral contract in order to work, this is done to prevent exploits on the referral system. 

## This repo contains OBX contracts, with tests, script that deploys the contracts, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/deploy.js
npx hardhat help
```

# BackEnd Smart Contracts for OBX Dex DAPP

## Main Contracts (POLYGON NETWORK)

### - LinkedListLib : [0x67DBb81B8922794f64a2aA311345Fb1B41a3EdE6](https://polygonscan.com/address/0x67dbb81b8922794f64a2aa311345fb1b41a3ede6)

### - OBXReferral : [0x894B3b0d0742221ce534D78Cddf7D15756eF997A](https://polygonscan.com/address/0x894B3b0d0742221ce534D78Cddf7D15756eF997A)

### - Factory : [0xfa41E14295Da290C94c4DB1eDe55DFB832A1aBed](https://polygonscan.com/address/0xfa41E14295Da290C94c4DB1eDe55DFB832A1aBed)


## Pairs

### - WMATIC/USDC > [0x293df706bCe0E0a25498654f4c0288E93a349CDF](https://polygonscan.com/address/0x293df706bCe0E0a25498654f4c0288E93a349CDF)

### - KRSTM/USDC > [0x1028d118493099ace65712890E06544cd5f08Da6](https://polygonscan.com/address/0x1028d118493099ace65712890E06544cd5f08Da6)

### - ETH/USDC > [0xeb4673b56A808F468Dea67DBD83BaC554f3F369B](https://polygonscan.com/address/0xeb4673b56A808F468Dea67DBD83BaC554f3F369B)

### - BNB/USDC > [0xc9A6Be04B9067C8a7c7a40eAC162B0Aa6c4Cb690](https://polygonscan.com/address/0xc9A6Be04B9067C8a7c7a40eAC162B0Aa6c4Cb690)

### - WBTC/USDC > [0xCe7D5C636A7A335dFcC0903CF18a8911399DaEcB](https://polygonscan.com/address/0xCe7D5C636A7A335dFcC0903CF18a8911399DaEcB)

### - LINK/USDC > [0x276274CC17800f440C87Dd78ABe545Aa65d7f367](https://polygonscan.com/address/0x276274CC17800f440C87Dd78ABe545Aa65d7f367)

### - USDT/USDC > [0x6Bc0476602C8A4d9e581171781F91d729A583543](https://polygonscan.com/address/0x6Bc0476602C8A4d9e581171781F91d729A583543)

### - WMATIC/BRZ > [0x4aAD72F11a2c0a2B126097a88e6EE4092428d2c1](https://polygonscan.com/address/0x4aAD72F11a2c0a2B126097a88e6EE4092428d2c1)

### - KRSTM/BRZ > [0xec59ad3A3Ad982F8a67B284679Bdba237E7CC133](https://polygonscan.com/address/0xec59ad3A3Ad982F8a67B284679Bdba237E7CC133)

### - ETH/BRZ > [0x465Cb43bf9d9fE84D463Bd00725bD40c977E9014](https://polygonscan.com/address/0x465Cb43bf9d9fE84D463Bd00725bD40c977E9014)

### - BNB/BRZ > [0xdba7ba2d9E89BCac95B83D1695E8a457225905f5](https://polygonscan.com/address/0xdba7ba2d9E89BCac95B83D1695E8a457225905f5)

### - WBTC/BRZ > [0x0b6feDd06fE33193EC2AddaC16340177AD4395d6](https://polygonscan.com/address/0x0b6feDd06fE33193EC2AddaC16340177AD4395d6)

### - USDC/BRZ > [0xcB68c6F13180A85646AeAbb487F5d40d98e1C1AD](https://polygonscan.com/address/0xcB68c6F13180A85646AeAbb487F5d40d98e1C1AD)
