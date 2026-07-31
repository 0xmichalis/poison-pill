// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

import { Test } from "forge-std/Test.sol";
import { WETH } from "solmate/tokens/WETH.sol";

import { PoisonPill } from "../src/PoisonPill.sol";
import { AggregatorV3Interface } from "../src/interfaces/AggregatorV3Interface.sol";
import { MockOracle } from "./mocks/MockOracle.sol";
import { MockToken } from "./mocks/MockToken.sol";

contract PoisonPillTest is Test {
    address constant deployer = address(0x69);
    address constant treasury = address(0x70);
    address constant alice = address(0x71);
    address constant sofia = address(0x72);
    address constant mallory = address(0xdead);
    address constant bob = address(0xb0b);

    WETH weth;
    MockToken usdc;
    MockToken token;

    MockOracle ethOracle;
    MockOracle tokenOracle;

    uint8 constant usdcDecimals = 6;
    uint8 constant tokenDecimals = 18;
    uint8 constant oracleDecimals = 8;

    int256 constant ethPrice = 3600e8;
    int256 constant tokenPrice = 100e8;
    uint16 constant discountBP = 1000; // 10% => effective price 90 USD
    uint32 constant maxOracleAge = 1 days;

    uint256 constant treasuryTokens = 1e9 * 10 ** tokenDecimals;

    PoisonPill pill;

    function setUp() public {
        token = new MockToken("Share", "SHR", tokenDecimals);
        usdc = new MockToken("USD Coin", "USDC", usdcDecimals);
        weth = new WETH();

        ethOracle = new MockOracle(ethPrice, oracleDecimals);
        tokenOracle = new MockOracle(tokenPrice, oracleDecimals);

        address[] memory whitelist = new address[](2);
        whitelist[0] = alice;
        whitelist[1] = sofia;

        vm.prank(deployer);
        pill = new PoisonPill(_config(address(tokenOracle), 0, 0, discountBP, whitelist));

        token.mint(address(pill), treasuryTokens);

        usdc.mint(alice, 2000 * 10 ** usdcDecimals);
        usdc.mint(mallory, 2000 * 10 ** usdcDecimals);

        vm.prank(alice);
        usdc.approve(address(pill), type(uint256).max);

        address[3] memory wethUsers = [sofia, mallory, bob];
        for (uint256 i = 0; i < wethUsers.length; ++i) {
            vm.deal(wethUsers[i], 2 ether);
            vm.startPrank(wethUsers[i]);
            weth.deposit{ value: 2 ether }();
            weth.approve(address(pill), type(uint256).max);
            vm.stopPrank();
        }

        vm.prank(mallory);
        usdc.approve(address(pill), type(uint256).max);
    }

    /// @dev Default config: USDC assumed pegged, WETH priced via ethOracle.
    function _config(
        address _tokenOracle,
        uint256 _price,
        uint8 _priceDecimals,
        uint16 _discount,
        address[] memory _whitelist
    ) internal view returns (PoisonPill.Config memory) {
        address[] memory assets = new address[](2);
        assets[0] = address(usdc);
        assets[1] = address(weth);
        address[] memory oracles = new address[](2);
        oracles[0] = address(0);
        oracles[1] = address(ethOracle);

        return PoisonPill.Config({
            token: address(token),
            tokenOracle: _tokenOracle,
            treasury: treasury,
            price: _price,
            priceDecimals: _priceDecimals,
            discountBP: _discount,
            maxOracleAge: maxOracleAge,
            paymentAssets: assets,
            paymentOracles: oracles,
            whitelist: _whitelist
        });
    }

    /*//////////////////////////////////////////////////////////////
                                REDEEM
    //////////////////////////////////////////////////////////////*/

    function test_RedeemWithPeggedStable() public {
        // 1800 USDC at 90 USD/token => 20 tokens
        vm.prank(alice);
        uint256 tokensOut = pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 20e18);

        assertEq(tokensOut, 20e18);
        assertEq(token.balanceOf(alice), 20e18);
        assertEq(usdc.balanceOf(address(pill)), 1800 * 10 ** usdcDecimals);
    }

    function test_RedeemWithOraclePricedAsset() public {
        // 0.5 WETH at 3600 USD/ETH = 1800 USD at 90 USD/token => 20 tokens
        vm.prank(sofia);
        uint256 tokensOut = pill.redeem(weth, 0.5 ether, 20e18);

        assertEq(tokensOut, 20e18);
        assertEq(token.balanceOf(sofia), 20e18);
        assertEq(weth.balanceOf(address(pill)), 0.5 ether);
    }

    function test_RedeemEmitsEvent() public {
        vm.expectEmit(true, true, false, true, address(pill));
        emit PoisonPill.Redeemed(alice, address(usdc), 1800 * 10 ** usdcDecimals, 20e18);

        vm.prank(alice);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
    }

    function test_ManualPriceOverridesOracle() public {
        vm.prank(deployer);
        pill.setPrice(200e8); // discounted to 180 => 10 tokens for 1800 USDC

        vm.prank(alice);
        uint256 tokensOut = pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);

        assertEq(tokensOut, 10e18);
    }

    function test_RedeemWithManualPriceOnly() public {
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;

        // no oracle, price already discounted: 90 USD with 8 decimals
        vm.prank(deployer);
        PoisonPill manualPill = new PoisonPill(_config(address(0), 90e8, oracleDecimals, 0, whitelist));
        token.mint(address(manualPill), treasuryTokens);

        vm.startPrank(alice);
        usdc.approve(address(manualPill), type(uint256).max);
        uint256 tokensOut = manualPill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
        vm.stopPrank();

        assertEq(tokensOut, 20e18);
    }

    function test_RedeemKeepsPrecisionOnSmallAmounts() public {
        // 95 USDC at 90 USD/token = 1.0555... tokens; must not truncate
        // at payment-token granularity (the old implementation divided
        // before scaling up to token decimals).
        vm.prank(alice);
        uint256 tokensOut = pill.redeem(usdc, 95 * 10 ** usdcDecimals, 0);

        assertEq(tokensOut, uint256(95e18 * 1e8) / 90e8);
        assertGt(tokensOut, 1e18);
    }

    function test_RedeemRevertsWhenNotWhitelisted() public {
        vm.prank(mallory);
        vm.expectRevert(PoisonPill.NotWhitelisted.selector);
        pill.redeem(usdc, 1000 * 10 ** usdcDecimals, 0);
    }

    function test_RedeemRevertsOnUnregisteredAsset() public {
        MockToken rogue = new MockToken("Rogue", "RGE", 18);
        rogue.mint(alice, 1e24);

        vm.startPrank(alice);
        rogue.approve(address(pill), type(uint256).max);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        pill.redeem(rogue, 1e18, 0);
        vm.stopPrank();
    }

    function test_RedeemRevertsOnZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(PoisonPill.ZeroAmount.selector);
        pill.redeem(usdc, 0, 0);
    }

    function test_RedeemRevertsWhenPayoutRoundsToZero() public {
        // 2-decimals token: 1e-6 USDC buys < 0.01 tokens => rounds to zero
        token = new MockToken("Coarse", "CRS", 2);
        address[] memory whitelist = new address[](1);
        whitelist[0] = alice;

        vm.prank(deployer);
        PoisonPill coarsePill = new PoisonPill(_config(address(tokenOracle), 0, 0, discountBP, whitelist));
        token.mint(address(coarsePill), 1e9 * 100);

        vm.startPrank(alice);
        usdc.approve(address(coarsePill), type(uint256).max);
        vm.expectRevert(PoisonPill.ZeroAmount.selector);
        coarsePill.redeem(usdc, 1, 0);
        vm.stopPrank();
    }

    function test_RedeemRevertsOnSlippage() public {
        vm.prank(alice);
        vm.expectRevert(PoisonPill.SlippageExceeded.selector);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 20e18 + 1);
    }

    function test_RedeemRevertsOnStaleTokenOracle() public {
        vm.warp(block.timestamp + maxOracleAge + 1);

        vm.prank(alice);
        vm.expectRevert(PoisonPill.StaleOraclePrice.selector);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
    }

    function test_RedeemRevertsOnStalePaymentOracle() public {
        vm.warp(block.timestamp + maxOracleAge + 1);
        tokenOracle.setAnswer(tokenPrice); // refresh token feed only

        vm.prank(sofia);
        vm.expectRevert(PoisonPill.StaleOraclePrice.selector);
        pill.redeem(weth, 0.5 ether, 0);
    }

    function test_RedeemRevertsOnNonPositiveOracleAnswer() public {
        tokenOracle.setAnswer(0);

        vm.prank(alice);
        vm.expectRevert(PoisonPill.InvalidOraclePrice.selector);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);

        tokenOracle.setAnswer(-1);

        vm.prank(alice);
        vm.expectRevert(PoisonPill.InvalidOraclePrice.selector);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
    }

    function testFuzz_RedeemStableConservesValue(uint256 amount) public {
        amount = bound(amount, 1, usdc.balanceOf(alice));

        vm.prank(alice);
        try pill.redeem(usdc, amount, 0) returns (uint256 tokensOut) {
            // USD value of tokens received never exceeds USD paid,
            // and undershoots by at most one payment-token unit.
            uint256 usdPaidWad = amount * 1e12;
            uint256 usdReceivedWad = tokensOut * 90e8 / 1e8;
            assertLe(usdReceivedWad, usdPaidWad);
            assertGt(usdReceivedWad + 1e12, usdPaidWad);
        } catch {
            // only acceptable failure below dust: zero tokens out
            assertEq(pill.previewRedeem(usdc, amount), 0);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             PAYMENT ASSETS
    //////////////////////////////////////////////////////////////*/

    function test_OwnerCanAddPeggedPaymentAsset() public {
        MockToken dai = new MockToken("Dai", "DAI", 18);
        dai.mint(alice, 1800e18);

        vm.prank(deployer);
        pill.addPaymentAsset(dai, AggregatorV3Interface(address(0)));

        vm.startPrank(alice);
        dai.approve(address(pill), type(uint256).max);
        uint256 tokensOut = pill.redeem(dai, 1800e18, 0);
        vm.stopPrank();

        assertEq(tokensOut, 20e18);
    }

    function test_OwnerCanAddOraclePricedPaymentAsset() public {
        MockToken wbtc = new MockToken("Wrapped BTC", "WBTC", 8);
        MockOracle btcOracle = new MockOracle(90_000e8, oracleDecimals);
        wbtc.mint(alice, 1e8);

        vm.prank(deployer);
        pill.addPaymentAsset(wbtc, btcOracle);

        // 0.01 BTC = 900 USD at 90 USD/token => 10 tokens
        vm.startPrank(alice);
        wbtc.approve(address(pill), type(uint256).max);
        uint256 tokensOut = pill.redeem(wbtc, 0.01e8, 0);
        vm.stopPrank();

        assertEq(tokensOut, 10e18);
    }

    function test_OwnerCanRemovePaymentAsset() public {
        vm.prank(deployer);
        pill.removePaymentAsset(usdc);

        vm.prank(alice);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
    }

    function test_RemovePaymentAssetRevertsWhenNotRegistered() public {
        MockToken rogue = new MockToken("Rogue", "RGE", 18);

        vm.prank(deployer);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        pill.removePaymentAsset(rogue);
    }

    function test_AddPaymentAssetRejectsTreasuryToken() public {
        vm.prank(deployer);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        pill.addPaymentAsset(token, tokenOracle);
    }

    /*//////////////////////////////////////////////////////////////
                               WHITELIST
    //////////////////////////////////////////////////////////////*/

    function test_OwnerCanWhitelistAndRevoke() public {
        vm.prank(bob);
        vm.expectRevert(PoisonPill.NotWhitelisted.selector);
        pill.redeem(weth, 0.5 ether, 0);

        vm.prank(deployer);
        pill.setWhitelisted(bob, true);

        vm.prank(bob);
        pill.redeem(weth, 0.5 ether, 0);
        assertEq(token.balanceOf(bob), 20e18);

        vm.prank(deployer);
        pill.setWhitelisted(bob, false);

        vm.prank(bob);
        vm.expectRevert(PoisonPill.NotWhitelisted.selector);
        pill.redeem(weth, 0.5 ether, 0);
    }

    function test_WhitelistBatch() public {
        address[] memory users = new address[](2);
        users[0] = bob;
        users[1] = mallory;

        vm.prank(deployer);
        pill.setWhitelistedBatch(users, true);

        assertTrue(pill.isWhitelisted(bob));
        assertTrue(pill.isWhitelisted(mallory));
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    function test_NonOwnerCannotAdmin() public {
        vm.startPrank(mallory);

        vm.expectRevert("UNAUTHORIZED");
        pill.setWhitelisted(mallory, true);

        vm.expectRevert("UNAUTHORIZED");
        pill.setPrice(1);

        vm.expectRevert("UNAUTHORIZED");
        pill.setDiscount(1);

        vm.expectRevert("UNAUTHORIZED");
        pill.setMaxOracleAge(1);

        vm.expectRevert("UNAUTHORIZED");
        pill.addPaymentAsset(usdc, ethOracle);

        vm.expectRevert("UNAUTHORIZED");
        pill.removePaymentAsset(usdc);

        vm.expectRevert("UNAUTHORIZED");
        pill.sweep();

        vm.stopPrank();
    }

    function test_SetDiscountRejectsFullDiscount() public {
        vm.startPrank(deployer);

        pill.setDiscount(9999);
        assertEq(pill.discountBP(), 9999);

        vm.expectRevert(PoisonPill.InvalidDiscount.selector);
        pill.setDiscount(10_000);

        vm.stopPrank();
    }

    function test_SetPriceZeroFallsBackToOracle() public {
        vm.startPrank(deployer);
        pill.setPrice(200e8);
        pill.setPrice(0);
        vm.stopPrank();

        assertEq(pill.discountedPrice(), 90e8);
    }

    function test_SetPriceZeroRevertsWithoutOracle() public {
        address[] memory whitelist = new address[](0);

        vm.startPrank(deployer);
        PoisonPill manualPill = new PoisonPill(_config(address(0), 90e8, oracleDecimals, 0, whitelist));

        vm.expectRevert(PoisonPill.PriceSourceRequired.selector);
        manualPill.setPrice(0);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                                TREASURY
    //////////////////////////////////////////////////////////////*/

    function test_AnyoneCanWithdrawProceedsToTreasury() public {
        vm.prank(alice);
        pill.redeem(usdc, 1800 * 10 ** usdcDecimals, 0);
        vm.prank(sofia);
        pill.redeem(weth, 1 ether, 0);

        vm.startPrank(mallory);
        pill.withdraw(usdc);
        pill.withdraw(weth);
        vm.stopPrank();

        assertEq(usdc.balanceOf(treasury), 1800 * 10 ** usdcDecimals);
        assertEq(weth.balanceOf(treasury), 1 ether);
        assertEq(usdc.balanceOf(address(pill)), 0);
        assertEq(weth.balanceOf(address(pill)), 0);
    }

    function test_WithdrawCannotDrainTreasuryToken() public {
        vm.prank(mallory);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        pill.withdraw(token);
    }

    function test_OwnerCanSweepUnsoldTokensToTreasury() public {
        vm.prank(deployer);
        pill.sweep();

        assertEq(token.balanceOf(treasury), treasuryTokens);
        assertEq(token.balanceOf(address(pill)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTION
    //////////////////////////////////////////////////////////////*/

    function test_ConstructorRejectsZeroAddresses() public {
        address[] memory whitelist = new address[](0);

        PoisonPill.Config memory config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.treasury = address(0);
        vm.expectRevert(PoisonPill.ZeroAddress.selector);
        new PoisonPill(config);

        config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.token = address(0);
        vm.expectRevert(PoisonPill.ZeroAddress.selector);
        new PoisonPill(config);

        config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.paymentAssets[0] = address(0);
        vm.expectRevert(PoisonPill.InvalidPaymentAsset.selector);
        new PoisonPill(config);
    }

    function test_ConstructorRequiresPaymentAssets() public {
        address[] memory whitelist = new address[](0);

        PoisonPill.Config memory config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.paymentAssets = new address[](0);
        config.paymentOracles = new address[](0);
        vm.expectRevert(PoisonPill.PaymentAssetRequired.selector);
        new PoisonPill(config);

        config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.paymentOracles = new address[](1);
        vm.expectRevert(PoisonPill.PaymentAssetRequired.selector);
        new PoisonPill(config);
    }

    function test_ConstructorRequiresPriceSource() public {
        address[] memory whitelist = new address[](0);

        vm.expectRevert(PoisonPill.PriceSourceRequired.selector);
        new PoisonPill(_config(address(0), 0, oracleDecimals, 0, whitelist));
    }

    function test_ConstructorRequiresDiscountWithOracle() public {
        address[] memory whitelist = new address[](0);

        vm.expectRevert(PoisonPill.DiscountRequiredWithOracle.selector);
        new PoisonPill(_config(address(tokenOracle), 0, 0, 0, whitelist));
    }

    function test_ConstructorRequiresPriceDecimalsWithManualPrice() public {
        address[] memory whitelist = new address[](0);

        vm.expectRevert(PoisonPill.PriceDecimalsRequired.selector);
        new PoisonPill(_config(address(0), 90e8, 0, 0, whitelist));
    }

    function test_ConstructorRejectsFullDiscount() public {
        address[] memory whitelist = new address[](0);

        vm.expectRevert(PoisonPill.InvalidDiscount.selector);
        new PoisonPill(_config(address(tokenOracle), 0, 0, 10_000, whitelist));
    }

    function test_ConstructorRejectsZeroMaxOracleAge() public {
        address[] memory whitelist = new address[](0);

        PoisonPill.Config memory config = _config(address(tokenOracle), 0, 0, discountBP, whitelist);
        config.maxOracleAge = 0;
        vm.expectRevert(PoisonPill.ZeroAmount.selector);
        new PoisonPill(config);
    }

    function test_ConstructorWhitelistsInitialUsers() public view {
        assertTrue(pill.isWhitelisted(alice));
        assertTrue(pill.isWhitelisted(sofia));
        assertFalse(pill.isWhitelisted(mallory));
    }
}
