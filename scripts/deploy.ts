import { ethers } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
    const usdc = process.env.USDC ? process.env.USDC : "";
    const weth = process.env.WETH ? process.env.WETH : "";
    const token = process.env.TOKEN ? process.env.TOKEN : "";
    const treasury = process.env.TREASURY ? process.env.TREASURY : "";
    const ethOracle = process.env.ETH_ORACLE ? process.env.ETH_ORACLE : "";
    const tokenOracle = process.env.TOKEN_ORACLE ? process.env.TOKEN_ORACLE : "";
    // TODO: Parse whitelist from env
    const price = process.env.PRICE ? Number(process.env.PRICE) : 0;
    const priceDecimals = process.env.PRICE_DECIMALS ? Number(process.env.PRICE_DECIMALS) : 0;
    const discountBp = process.env.DISCOUNT ? Number(process.env.DISCOUNT) : 0;

    const PoisonPill = await ethers.getContractFactory("PoisonPill");
    const poisonPill = await PoisonPill.deploy(
        usdc,
        weth,
        token,
        ethOracle,
        tokenOracle,
        treasury,
        [],
        price,
        priceDecimals,
        discountBp,
    );
    await poisonPill.deployed();

    console.log("PoisonPill deployed to:", poisonPill.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
