// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

import { Script } from "forge-std/Script.sol";

import { PoisonPill } from "../src/PoisonPill.sol";

/// @notice Deploys a PoisonPill configured entirely through environment
/// variables — see .env.example for the full list.
contract Deploy is Script {
    function run() external returns (PoisonPill pill) {
        PoisonPill.Config memory config = PoisonPill.Config({
            token: vm.envAddress("TOKEN_ADDRESS"),
            tokenOracle: vm.envOr("TOKEN_ORACLE", address(0)),
            treasury: vm.envAddress("TREASURY_ADDRESS"),
            price: vm.envOr("TOKEN_PRICE", uint256(0)),
            priceDecimals: uint8(vm.envOr("TOKEN_PRICE_DECIMALS", uint256(0))),
            discountBP: uint16(vm.envUint("TOKEN_DISCOUNT_BASIS_POINTS")),
            maxOracleAge: uint32(vm.envOr("MAX_ORACLE_AGE", uint256(1 days))),
            paymentAssets: vm.envAddress("PAYMENT_ASSETS", ","),
            paymentOracles: vm.envAddress("PAYMENT_ORACLES", ","),
            whitelist: vm.envOr("WHITELIST", ",", new address[](0))
        });

        vm.startBroadcast();
        pill = new PoisonPill(config);
        vm.stopBroadcast();
    }
}
