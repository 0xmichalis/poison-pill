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
  let signers: SignerWithAddress[];
  before(async () => {
    signers = await ethers.getSigners();
  });

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
      console.log(`USDC: ${usdc.address}`);

      weth = await (await getFactory<WETH__factory>("WETH")).deploy();
      await weth.deployed();
      console.log(`WETH: ${weth.address}`);

      wethOracle = await (
        await getFactory<TestPriceOracle__factory>("TestPriceOracle")
      ).deploy(4100, 8);
      await wethOracle.deployed();
      console.log(`WETH oracle: ${wethOracle.address}`);

      token = await (
        await getFactory<TestToken__factory>("TestToken")
      ).deploy(18);
      await token.deployed();
      console.log(`Token: ${token.address}`);

      tokenOracle = await (
        await getFactory<TestPriceOracle__factory>("TestPriceOracle")
      ).deploy(100, 8);
      await tokenOracle.deployed();
      console.log(`Token oracle: ${tokenOracle.address}`);
    });

    it("should properly deploy the poison pill", async function () {
      console.log(`USDC: ${usdc.address}`);
      console.log(`WETH: ${weth.address}`);
      console.log(`WETH oracle: ${wethOracle.address}`);
      console.log(`Token: ${token.address}`);
      console.log(`Token oracle: ${tokenOracle.address}`);

      poisonPill = await (
        await getFactory<PoisonPill__factory>("PoisonPill")
      ).deploy(
        usdc.address,
        weth.address,
        token.address,
        wethOracle.address,
        tokenOracle.address,
        signers[1].address,
        [],
        0,
        1000
      );
      await poisonPill.deployed();
    });
  });

  // it("should deploy mock contracts", async function () {
  //   const PoisonPill = await ethers.getContractFactory("PoisonPill");
  //   const pp = await PoisonPill.deploy("Hello, world!");
  //   await pp.deployed();

  //   expect(await greeter.greet()).to.equal("Hello, world!");

  //   const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

  //   // wait until the transaction is mined
  //   await setGreetingTx.wait();

  //   expect(await greeter.greet()).to.equal("Hola, mundo!");
  // });
});
