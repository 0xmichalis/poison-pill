/* eslint-disable camelcase */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

import {
  PoisonPill,
  PoisonPill__factory,
  TestPriceOracle,
  TestPriceOracle__factory,
  TestToken,
  TestToken__factory,
  USDC,
  USDC__factory,
  WETH,
  WETH__factory,
} from "../typechain";

export function getFactory<T>(name: string): Promise<T> {
  return ethers.getContractFactory(name) as any;
}

describe("PoisonPill", function () {
  let deployer: SignerWithAddress;
  let treasury: SignerWithAddress;
  let trustedUser: SignerWithAddress;
  let untrustedUser: SignerWithAddress;

  before(async () => {
    [deployer, treasury, trustedUser, untrustedUser] =
      await ethers.getSigners();
  });

  const oracleDecimals = 8;
  const tokenDecimals = 18;
  const usdcDecimals = 6;
  const wethDecimals = 18;

  let usdc: USDC;
  let weth: WETH;
  let wethOracle: TestPriceOracle;
  let token: TestToken;
  let tokenOracle: TestPriceOracle;
  let poisonPill: PoisonPill;

  describe("setup w/ price oracle", function () {
    it("should properly deploy mocks", async function () {
      usdc = await (await getFactory<USDC__factory>("USDC")).deploy();
      await usdc.deployed();

      weth = await (await getFactory<WETH__factory>("WETH")).deploy();
      await weth.deployed();

      wethOracle = await (
        await getFactory<TestPriceOracle__factory>("TestPriceOracle")
      ).deploy(4100, oracleDecimals);
      await wethOracle.deployed();

      token = await (
        await getFactory<TestToken__factory>("TestToken")
      ).deploy(tokenDecimals);
      await token.deployed();

      tokenOracle = await (
        await getFactory<TestPriceOracle__factory>("TestPriceOracle")
      ).deploy(100, oracleDecimals);
      await tokenOracle.deployed();
    });

    it("should properly prime user balances", async function () {
      await token
        .connect(deployer)
        .mint(treasury.address, 1000000 * tokenDecimals);
      expect(await token.balanceOf(treasury.address)).to.equal(
        1000000 * tokenDecimals
      );

      await usdc
        .connect(deployer)
        .mint(trustedUser.address, 2000 * usdcDecimals);
      expect(await usdc.balanceOf(trustedUser.address)).to.equal(
        2000 * usdcDecimals
      );

      await usdc
        .connect(deployer)
        .mint(untrustedUser.address, 2000 * usdcDecimals);
      expect(await usdc.balanceOf(untrustedUser.address)).to.equal(
        2000 * usdcDecimals
      );
    });

    it("should properly deploy the poison pill", async function () {
      poisonPill = await (
        await getFactory<PoisonPill__factory>("PoisonPill")
      ).deploy(
        usdc.address,
        weth.address,
        token.address,
        wethOracle.address,
        tokenOracle.address,
        treasury.address,
        [trustedUser.address],
        0,
        1000
      );
      await poisonPill.deployed();
    });
  });
});
