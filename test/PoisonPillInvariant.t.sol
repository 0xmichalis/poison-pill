// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

import { Test } from "forge-std/Test.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { WETH } from "solmate/tokens/WETH.sol";

import { PoisonPill } from "../src/PoisonPill.sol";
import { MockOracle } from "./mocks/MockOracle.sol";
import { MockToken } from "./mocks/MockToken.sol";

/// @dev Drives the pill with bounded, valid operations while tracking
/// ghost accounting. Owns the pill so admin actions need no pranking.
contract Handler is Test {
    PoisonPill public immutable pill;
    MockToken public immutable token;
    MockToken public immutable usdc;
    WETH public immutable weth;
    MockOracle public immutable ethOracle;
    MockOracle public immutable tokenOracle;
    address public immutable treasury;

    address[] public actors;

    uint256 public ghost_usdPaidWad;
    uint256 public ghost_usdSoldWad;
    uint256 public ghost_totalMinted;
    mapping(ERC20 => uint256) public ghost_paid;
    mapping(address => bool) public ghost_everWhitelisted;

    int256 ethPrice = 3600e8;
    int256 tokenPrice = 100e8;

    constructor(address _treasury) {
        treasury = _treasury;

        token = new MockToken("Share", "SHR", 18);
        usdc = new MockToken("USD Coin", "USDC", 6);
        weth = new WETH();
        ethOracle = new MockOracle(ethPrice, 8);
        tokenOracle = new MockOracle(tokenPrice, 8);

        actors.push(address(0xa11ce));
        actors.push(address(0x50f1a));
        actors.push(address(0xb0b));
        actors.push(address(0xca7));

        address[] memory assets = new address[](2);
        assets[0] = address(usdc);
        assets[1] = address(weth);
        address[] memory oracles = new address[](2);
        oracles[0] = address(0);
        oracles[1] = address(ethOracle);
        address[] memory whitelist = new address[](2);
        whitelist[0] = actors[0];
        whitelist[1] = actors[1];
        ghost_everWhitelisted[actors[0]] = true;
        ghost_everWhitelisted[actors[1]] = true;

        pill = new PoisonPill(
            PoisonPill.Config({
                token: address(token),
                tokenOracle: address(tokenOracle),
                treasury: treasury,
                price: 0,
                priceDecimals: 0,
                discountBP: 1000,
                maxOracleAge: 1 days,
                paymentAssets: assets,
                paymentOracles: oracles,
                whitelist: whitelist
            })
        );

        token.mint(address(pill), 1e9 * 1e18);
        ghost_totalMinted = 1e9 * 1e18;
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }

    /*//////////////////////////////////////////////////////////////
                                ACTIONS
    //////////////////////////////////////////////////////////////*/

    function redeem(uint256 actorSeed, bool useUsdc, uint256 amount) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];
        if (!pill.isWhitelisted(actor)) return;

        ERC20 asset;
        uint256 usdWad;
        if (useUsdc) {
            amount = bound(amount, 1, 1e13); // up to 10M USDC
            asset = ERC20(address(usdc));
            usdc.mint(actor, amount);
            usdWad = amount * 1e12;
        } else {
            amount = bound(amount, 1, 1000e18);
            asset = ERC20(address(weth));
            vm.deal(actor, amount);
            vm.prank(actor);
            weth.deposit{ value: amount }();
            usdWad = amount * uint256(ethOracle.answer()) / 1e8;
        }

        uint256 preview = pill.previewRedeem(asset, amount);
        if (preview == 0 || preview > token.balanceOf(address(pill))) return;

        vm.startPrank(actor);
        asset.approve(address(pill), amount);
        uint256 tokensOut = pill.redeem(asset, amount, 0);
        vm.stopPrank();

        ghost_paid[asset] += amount;
        ghost_usdPaidWad += usdWad;
        // tokens (18 dec) valued at the discounted price (8 dec) => WAD
        ghost_usdSoldWad += tokensOut * pill.discountedPrice() / 1e8;
    }

    function setPrice(uint256 newPrice) external {
        // zero falls back to the oracle; otherwise keep the discounted
        // price representable (> 0)
        newPrice = bound(newPrice, 0, 100_000e8);
        if (newPrice < 1e4) newPrice = 0;

        pill.setPrice(newPrice);
    }

    function setDiscount(uint256 newDiscountBP) external {
        pill.setDiscount(uint16(bound(newDiscountBP, 0, 9999)));
    }

    function movePrices(uint256 newEthPrice, uint256 newTokenPrice) external {
        ethOracle.setAnswer(int256(bound(newEthPrice, 100e8, 100_000e8)));
        tokenOracle.setAnswer(int256(bound(newTokenPrice, 1e8, 100_000e8)));
    }

    function toggleWhitelist(uint256 actorSeed, bool whitelisted) external {
        address actor = actors[bound(actorSeed, 0, actors.length - 1)];

        pill.setWhitelisted(actor, whitelisted);
        if (whitelisted) ghost_everWhitelisted[actor] = true;
    }

    function withdrawProceeds(bool isUsdc) external {
        pill.withdraw(isUsdc ? ERC20(address(usdc)) : ERC20(address(weth)));
    }

    function sweep() external {
        pill.sweep();
    }

    function mintToPill(uint256 amount) external {
        amount = bound(amount, 0, 1e6 * 1e18);

        token.mint(address(pill), amount);
        ghost_totalMinted += amount;
    }

    function warpAndRefreshOracles(uint256 secondsAhead) external {
        vm.warp(block.timestamp + bound(secondsAhead, 1, 6 hours));

        // keep feeds fresh so redeems remain valid operations
        ethOracle.setAnswer(ethOracle.answer());
        tokenOracle.setAnswer(tokenOracle.answer());
    }
}

contract PoisonPillInvariantTest is Test {
    address constant treasury = address(0x70);

    Handler handler;
    PoisonPill pill;

    function setUp() public {
        handler = new Handler(treasury);
        pill = handler.pill();

        targetContract(address(handler));
    }

    /// @notice The pill never hands out more USD value (at the discounted
    /// price in effect at sale time) than it was paid; rounding always
    /// favors the pill.
    function invariant_PillNeverOverpays() public view {
        assertLe(handler.ghost_usdSoldWad(), handler.ghost_usdPaidWad());
    }

    /// @notice Every unit of payment ever collected is either still in the
    /// pill or has been pushed to the treasury — proceeds cannot leak.
    function invariant_ProceedsFullyAccounted() public view {
        ERC20 usdc = ERC20(address(handler.usdc()));
        ERC20 weth = ERC20(address(handler.weth()));

        assertEq(usdc.balanceOf(address(pill)) + usdc.balanceOf(treasury), handler.ghost_paid(usdc));
        assertEq(weth.balanceOf(address(pill)) + weth.balanceOf(treasury), handler.ghost_paid(weth));
    }

    /// @notice Treasury tokens only ever sit with the pill, redeemers, or
    /// the treasury; none are minted from thin air or destroyed.
    function invariant_TokenConservation() public view {
        ERC20 token = ERC20(address(handler.token()));

        uint256 actorHoldings;
        for (uint256 i = 0; i < handler.actorCount(); ++i) {
            actorHoldings += token.balanceOf(handler.actors(i));
        }

        assertEq(
            token.balanceOf(address(pill)) + token.balanceOf(treasury) + actorHoldings, handler.ghost_totalMinted()
        );
    }

    /// @notice Nobody who was never whitelisted can end up holding tokens.
    function invariant_OnlyEverWhitelistedHoldTokens() public view {
        ERC20 token = ERC20(address(handler.token()));

        for (uint256 i = 0; i < handler.actorCount(); ++i) {
            address actor = handler.actors(i);
            if (token.balanceOf(actor) > 0) {
                assertTrue(handler.ghost_everWhitelisted(actor));
            }
        }
    }

    /// @notice Configuration can never reach a state that breaks pricing:
    /// full discounts are impossible and a price source always exists.
    function invariant_ConfigBounds() public view {
        assertLt(pill.discountBP(), 10_000);
        assertGt(pill.maxOracleAge(), 0);
        assertTrue(pill.price() != 0 || address(pill.tokenOracle()) != address(0));
        assertGt(pill.discountedPrice(), 0);
    }
}
