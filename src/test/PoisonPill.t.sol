//SPDX-License-Identifier: Anti-996 License
pragma solidity ^0.8.10;

import { DSTest } from "ds-test/test.sol";

import { VM } from "./utils/VM.sol";
import { PoisonPill } from "../PoisonPill.sol";
import { TestPriceOracle } from "./mocks/TestPriceOracle.sol";
import { TestToken } from "./mocks/TestToken.sol";
import { USDC } from "./mocks/USDC.sol";
import { WETH } from "./mocks/WETH.sol";

contract PoisonPillTest is DSTest {
    // God
    VM constant vm = VM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    // users
    address constant deployer = address(0x69);
    address constant treasury = address(0x70);
    address constant alice = address(0x71);
    address constant sofia = address(0x72);
    address constant mallory = address(0xdead);
    address constant bob = address(0xb0b);

    // tokens
    WETH weth;
    USDC usdc;
    TestToken token;

   // oracles
    TestPriceOracle ethOracle;
    TestPriceOracle tokenOracle;

    // decimals
    uint8 constant ethDecimals = 18;
    uint8 constant usdcDecimals = 6;
    uint8 constant tokenDecimals = 18;
    uint8 constant oracleDecimals = 8;

    // balances, prices
    uint256 usdcBalance = 1800 * 10 ** usdcDecimals;
    uint256 wethBalance = 1 ether / 2;
    uint256 tokenPrice = 100 * 10 ** oracleDecimals;

    // the contract of the hour
    PoisonPill pill;

    function setUp() public {
        // tokens
        token = new TestToken(tokenDecimals);
        weth = new WETH();
        usdc = new USDC();

        // oracles
        ethOracle = new TestPriceOracle(3600 * 10 ** oracleDecimals, oracleDecimals);
        tokenOracle = new TestPriceOracle(tokenPrice, oracleDecimals);

        // initial set of trusted users
        address[] memory initialTrustedUsers = new address[](2);
        initialTrustedUsers[0] = alice;
        initialTrustedUsers[1] = sofia;

        // prime account balances
        vm.deal(deployer, 1 ether);
        vm.deal(treasury, 1 ether);
        vm.deal(alice, 1 ether);
        vm.deal(sofia, 1 ether);
        vm.deal(mallory, 1 ether);
        vm.deal(bob, 1 ether);
        uint256 treasuryBalance = 1e9 * 10 ** tokenDecimals;
        token.mint(treasury, treasuryBalance);
        usdc.mint(alice, 2000 * 10 ** usdcDecimals);
        usdc.mint(sofia, 6000 * 10 ** usdcDecimals);
        usdc.mint(mallory, 2000 * 10 ** usdcDecimals);

        // deploy the pill
        vm.prank(deployer);
        pill = new PoisonPill(
            address(usdc),
            address(weth),
            address(token),
            address(ethOracle),
            address(tokenOracle),
            treasury,
            initialTrustedUsers,
            0,
            0,
            1000 // 10%
        );

        // transfer funds from treasury to the pill contract
        vm.prank(treasury);
        token.transfer(address(pill), treasuryBalance);

        // user approvals out of the way
        vm.prank(alice);
        usdc.approve(address(pill), usdcBalance);

        vm.startPrank(sofia);
        weth.deposit{ value: 2 * wethBalance }();
        weth.approve(address(pill), 2 * wethBalance);
        usdc.approve(address(pill), 3 * usdcBalance);
        vm.stopPrank();

        vm.startPrank(mallory);
        weth.deposit{ value: wethBalance }();
        weth.approve(address(pill), wethBalance);
        usdc.approve(address(pill), usdcBalance);
        vm.stopPrank();

        vm.startPrank(bob);
        weth.deposit{ value: wethBalance }();
        weth.approve(address(pill), wethBalance);
        vm.stopPrank();
    }

    /************************************************
     *  TESTS
     ***********************************************/

    function testTrustedUserUsdcDeposit() public {
        vm.prank(alice);
        pill.redeem(usdcBalance, true);
        assertEq(token.balanceOf(address(alice)), 20 * 10 ** tokenDecimals);
    }

    function testTrustedUserWethDeposit() public {
        tokenOracle.setPrice(tokenPrice * 2);

        vm.prank(sofia);
        pill.redeem(wethBalance, false);
        assertEq(token.balanceOf(address(sofia)), 10 * 10 ** tokenDecimals);
    }

    function testFail_UntrustedUserUsdcDeposit() public {
        vm.prank(mallory);
        pill.redeem(usdcBalance, true);
        revert("unreachable");
    }

    function testFail_UntrustedUserWethDeposit() public {
        vm.prank(mallory);
        pill.redeem(wethBalance, false);
        revert("unreachable");
    }

    function testFail_NonAdminExecutesAdminTask() public {
        vm.prank(mallory);
        pill.setIsTrusted(mallory, true);
        revert("unreachable");
    }

    function testFail_NonAdminExecutesAdminTask2() public {
        vm.prank(alice);
        pill.setIsTrusted(alice, true);
        revert("unreachable");
    }

    function testWhitelistUser() public {
        vm.prank(bob);
        try pill.redeem(wethBalance, false) {
            revert("should not have redeemed");
        } catch {}

        vm.prank(deployer);
        pill.setIsTrusted(bob, true);

        vm.prank(bob);
        pill.redeem(wethBalance, false);
        assertEq(token.balanceOf(address(bob)), 20 * 10 ** tokenDecimals);
    }

    function testTreasuryWithdraw() public {
        assertEq(weth.balanceOf(treasury), 0);
        assertEq(usdc.balanceOf(treasury), 0);

        vm.startPrank(sofia);
        pill.redeem(wethBalance, false);
        pill.redeem(wethBalance, false);
        pill.redeem(3 * usdcBalance, true);
        vm.stopPrank();

        vm.prank(alice);
        pill.redeem(usdcBalance, true);

        vm.prank(mallory);
        pill.withdraw();

        assertEq(weth.balanceOf(treasury), 2 * wethBalance);
        assertEq(usdc.balanceOf(treasury), 4 * usdcBalance);
    }
}
