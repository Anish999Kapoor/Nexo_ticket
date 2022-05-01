# NEXO LOTTERY

An On-Chain secure and transparent lottery system which allows users to purchase lottery tickets as NFTs and after a set time, picks up a random winner amongst the participants and distribute the reward i.e 50% of the collected amount (prize Pool).

**Instructions :**
1) git clone
2) cd Nexo_ticket
3) npm install
4) npx hardhat test

**Note : Try re-running tests if it shows error in reward distribution test case because of instability in Eth transfers.**


**Blockchain Network :** Rinkeby Testnet ([https://rinkeby.etherscan.io/](https://rinkeby.etherscan.io/))

**Deploy Scripts Results :**

**deploy.js ⇒**                

```jsx
factory deployed at: 0xFd7cfB9cE151aE8aC815a9495a9a258658c7007e
customERC721 deployed at: 0x4D40C0E3D5C5a7B77bbb647471Cfe5716F23d504
tickets proxy deployed at: 0x764957EaC17672694AC851D24532a3eA7C67717E
tickets implementation deployed at: 0xcC1E30BfcD92617F177613bc006024BFD6296aEF
```

**upgradeProxy.js ⇒**

```jsx
tickets upgraded
tickets upgraded implementation address: 0x6CB104fA3467c75C4709f01d02E5d1fCC1439aD1
```

**Deploy Commands Instructions :** 

1. cd Nexo_ticket/scripts
2. npx hardhat run ‘network’ ‘script name’
```
