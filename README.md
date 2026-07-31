# Poison pill

[![CI](https://github.com/0xmichalis/poison-pill/actions/workflows/ci.yml/badge.svg)](https://github.com/0xmichalis/poison-pill/actions/workflows/ci.yml)
[![LICENSE](https://img.shields.io/badge/license-Anti%20996-blue.svg?style=flat-square)](https://github.com/996icu/996.ICU/blob/master/LICENSE)

On-chain defense against hostile takeovers. In layman's terms, this smart contract
only facilitates a discounted sale of shares to a whitelisted group.

More info on the concept of a poison pill can be found below:
* https://www.investopedia.com/terms/p/poisonpill.asp
* https://twitter.com/GuardAOR/status/1476271943351427078

## Design

* **Whitelisted sale** — only accounts whitelisted by the owner can `redeem`.
  The whitelist can be updated at any time, individually or in batches.
* **Configurable payment assets** — the pill accepts any set of ERC20s as
  payment. Each asset is valued through its own Chainlink-compatible USD feed,
  or assumed to hold a 1:1 USD peg when no feed is configured (e.g. USDC).
  Assets can be added and removed post-deployment.
* **Two price sources for the token** — a Chainlink-compatible feed, or a
  manually maintained `price` for tokens with no on-chain feed. A non-zero
  manual price always overrides the feed. `discountBP` basis points are shaved
  off whichever price applies.
* **Oracle hygiene** — feeds are read via `latestRoundData`; non-positive
  answers revert, and answers older than `maxOracleAge` revert.
* **Slippage protection** — `redeem` takes `minTokensOut` so buyers cannot be
  front-run by price updates.
* **One-way funds** — `withdraw` pushes proceeds to the treasury and is
  callable by anyone; it cannot touch the treasury token, so nobody can defuse
  the pill mid-sale. `sweep` recovers unsold treasury tokens, is owner-only,
  and also only ever pays out to the treasury.

## How to use

0. Off-chain process in `$TOKEN` entity (corporate or DAO) triggers the need to
use a poison pill. It is assumed that shares in the entity are represented as an
ERC20 token.
1. Deploy the pill with the initial whitelist, payment assets, and one of the
two token price sources (feed or manual price) — see [.env.example](./.env.example)
for the full parameter list.
2. Move the funds to sell from the entity's treasury to the pill contract. The
goal of the pill is to deter an attacker attempting a takeover and/or bring them
to the negotiation table, so management can fund the pill in batches rather than
all at once. If the attacker backs off, the owner can `sweep` unsold tokens back
to the treasury.
3. Whitelisted users buy `$TOKEN` at a discount with any registered payment asset
via `redeem` (`previewRedeem` quotes the current rate).
4. Anyone can push accumulated proceeds back to the treasury via `withdraw`.

## Development

[Foundry](https://getfoundry.sh) under the hood. The test suite includes unit,
fuzz, and invariant tests; [Slither](https://github.com/crytic/slither) runs in
CI and the source is kept finding-free.

```
make build   # compile
make test    # unit + fuzz + invariant tests
make fmt     # format
make lint    # formatting check + slither
```

Find a variety of Chainlink feeds to test with at https://data.chain.link.

## Deploy on Sepolia

Copy `.env.example` to `.env`, fill in your parameters, then:

```
make deploy-sepolia
```

## Disclaimer

These smart contracts are being provided as is. No guarantee, representation, or
warranty is being made, express or implied, as to the safety or correctness of
any code provided in this repository. The contracts have not been audited and as
such there can be no assurance they will work as intended, and users may
experience delays, failures, errors, omissions, loss of transmitted information,
or loss of funds. The original author is not liable for any of the foregoing.
Users should proceed with caution and use at their own risk. On top of this,
nothing in this repository constitutes legal advice. Please advise with a lawyer
before executing the poison pill strategy.
