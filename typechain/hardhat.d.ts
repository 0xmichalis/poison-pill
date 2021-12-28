/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "Auth",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Auth__factory>;
    getContractFactory(
      name: "Authority",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Authority__factory>;
    getContractFactory(
      name: "Trust",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Trust__factory>;
    getContractFactory(
      name: "ERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: "IERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: "IPriceOracle",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IPriceOracle__factory>;
    getContractFactory(
      name: "IWETH",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IWETH__factory>;
    getContractFactory(
      name: "PoisonPill",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.PoisonPill__factory>;
    getContractFactory(
      name: "TestPriceOracle",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TestPriceOracle__factory>;
    getContractFactory(
      name: "TestToken",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.TestToken__factory>;
    getContractFactory(
      name: "USDC",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.USDC__factory>;
    getContractFactory(
      name: "WETH",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.WETH__factory>;

    getContractAt(
      name: "Auth",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Auth>;
    getContractAt(
      name: "Authority",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Authority>;
    getContractAt(
      name: "Trust",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Trust>;
    getContractAt(
      name: "ERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: "IERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: "IPriceOracle",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IPriceOracle>;
    getContractAt(
      name: "IWETH",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IWETH>;
    getContractAt(
      name: "PoisonPill",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.PoisonPill>;
    getContractAt(
      name: "TestPriceOracle",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TestPriceOracle>;
    getContractAt(
      name: "TestToken",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.TestToken>;
    getContractAt(
      name: "USDC",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.USDC>;
    getContractAt(
      name: "WETH",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.WETH>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}
