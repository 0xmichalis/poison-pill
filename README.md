# Poison pill

[![LICENSE](https://img.shields.io/badge/license-Anti%20996-blue.svg?style=flat-square)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

On-chain defense against hostile takeovers. In layman's terms, this smart contract
only facilitates a discounted sale of shares to a whitelisted group.

More info on the concept of a poison pill can be found below:
* https://www.investopedia.com/terms/p/poisonpill.asp
* https://twitter.com/GuardAOR/status/1476271943351427078

## How to use

0. Off-chain process in `$TOKEN` entity (corporate or DAO) triggers the need to use a poison
pill. It is assumed that shares in the entity are represented as an ERC20 token.
1. Deploy the poison pill with an initial set of whitelisted accounts. The whitelist can
also be updated post-deployment. There are two ways to facilitate a discount on `$TOKEN` via
this contract:
* set `_tokenOracle` to a price oracle that supports the [`IPriceOracle`](./contracts/interfaces/IPriceOracle.sol) interface, eg. Chainlink.
  Set `_discountBP` to the basis points you want to discount from the market price returned from the price oracle.
* if no `$TOKEN` price feed exists on-chain, it is still possible to maintain the market
  price of `$TOKEN` manually directly in the contract via `_price`. At this point, you can either
  set `_price` directly to the discounted price, in which case `_discountBP` should be set to zero,
  or set to market price and specify the discount separately.
2. Once the contract is deployed, the last step that needs to happen before the sale starts is to move
the funds to sell from the entity's treasury to the smart contract. The ultimate goal of the pill is to
deter some attacker who tries to take over the entity and/or bring them to the negotiation table. This means
that it is up to the entity's management to determine how to execute the poison pill, before the attacker
backs outs. Hence, this step can be repeated more than once, eg., entity agrees to start selling batches of
their treasury and not all of it in one go. Obviously, this process is out of scope of the smart contract
but it can still be facilitated.
3. Now, whitelisted users can use `$WETH` or `$USDC` to start buying `$TOKEN` in discount.
4. Any acquired `$WETH` or `$USDC` can be withdrawn by anyone back to the treasury.

## Build

```
yarn
yarn build
```

## Test

```
yarn test
```

Find a variety of Chainlink feeds to test with at https://market.link.

## Deploy in Ropsten

Copy `.env.example` to `.env` and configure accordingly. Once you have all the config
in place, you can deploy with the following command:
```
yarn deploy ropsten ./scripts/deploy.ts
```
Update the Hardhat config and `.env` accordinly to deploy in Mainnet.

## Disclaimer

These smart contracts are being provided as is. No guarantee, representation, or warranty is being made,
express or implied, as to the safety or correctness of any code provided in this repository. The contracts
have not been audited and as such there can be no assurance they will work as intended, and users may
experience delays, failures, errors, omissions, loss of transmitted information, or loss of funds. The
original author is not liable for any of the foregoing. Users should proceed with caution and use at their
own risk. On top of this, nothing in this repository constitutes legal advice. Please advise with a lawyer
before executing the poison pill strategy.
