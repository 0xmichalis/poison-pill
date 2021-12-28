/* eslint-disable camelcase */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";
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
  let trustedUser1: SignerWithAddress;
  let trustedUser2: SignerWithAddress;
  let untrustedUser: SignerWithAddress;

  before(async () => {
    [deployer, treasury, trustedUser1, trustedUser2, untrustedUser] =
      await ethers.getSigners();
  });

  const oracleDecimals = 8;
  const tokenDecimals = 18;
  const usdcDecimals = 6;
  const wethDecimals = 18;
  const treasuryTokenBalance = parseUnits("1000000", tokenDecimals);

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
      ).deploy(parseUnits("3900", oracleDecimals), oracleDecimals);
      await wethOracle.deployed();

      token = await (
        await getFactory<TestToken__factory>("TestToken")
      ).deploy(tokenDecimals);
      await token.deployed();

      tokenOracle = await (
        await getFactory<TestPriceOracle__factory>("TestPriceOracle")
      ).deploy(parseUnits("100", oracleDecimals), oracleDecimals);
      await tokenOracle.deployed();
    });

    it("should properly prime user balances", async function () {
      await token
        .connect(deployer)
        .mint(treasury.address, treasuryTokenBalance);
      expect(await token.balanceOf(treasury.address)).to.equal(
        treasuryTokenBalance
      );

      const userUsdcBalance = parseUnits("2000", usdcDecimals);
      await usdc.connect(deployer).mint(trustedUser1.address, userUsdcBalance);
      expect(await usdc.balanceOf(trustedUser1.address)).to.equal(
        userUsdcBalance
      );

      const userEthBalance = parseEther("0.5");
      await weth.connect(trustedUser2).deposit({ value: userEthBalance });
      expect(await weth.balanceOf(trustedUser2.address)).to.equal(
        userEthBalance
      );

      await usdc.connect(deployer).mint(untrustedUser.address, userUsdcBalance);
      expect(await usdc.balanceOf(untrustedUser.address)).to.equal(
        userUsdcBalance
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
        [trustedUser1.address, trustedUser2.address],
        0,
        0,
        1000
      );
      await poisonPill.deployed();
    });

    it("should transfer treasury funds to poison pill", async function () {
      await token
        .connect(treasury)
        .transfer(poisonPill.address, treasuryTokenBalance);
      expect(await token.balanceOf(poisonPill.address)).to.equal(
        treasuryTokenBalance
      );
    });

    it("should allow trusted user to take the pill", async function () {
      // 200 USDC
      const usdcBalance = parseUnits("2000", usdcDecimals);
      // Oracle price is 100 so the user should get 20 TestTokens
      const tokenBalance = parseUnits("20", tokenDecimals);
      await usdc.connect(trustedUser1).approve(poisonPill.address, usdcBalance);
      await poisonPill.connect(trustedUser1).redeem(usdcBalance, true);
      expect(await token.balanceOf(trustedUser1.address)).to.equal(
        tokenBalance
      );
    });
  });
});
