// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

import { Owned } from "solmate/auth/Owned.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

import { AggregatorV3Interface } from "./interfaces/AggregatorV3Interface.sol";

/// @title PoisonPill
/// @notice On-chain defense against hostile takeovers: sells an entity's
/// treasury token at a discount, exclusively to a whitelisted group.
///
/// Token price discovery, in order of precedence:
/// 1. `price` — a manually maintained price (quoted with `priceDecimals`
///    decimals). Whenever non-zero it overrides the oracle.
/// 2. `tokenOracle` — a Chainlink-compatible USD feed for the token.
///
/// `discountBP` basis points are shaved off whichever price applies.
///
/// Payment is accepted in any registered asset. Each asset is valued
/// either through its own Chainlink-compatible USD feed or, when no feed
/// is configured, assumed to be a stablecoin holding a 1:1 USD peg.
///
/// Proceeds can be pushed to the treasury by anyone; unsold treasury
/// tokens can only be recovered by the owner, and only back to the
/// treasury.
contract PoisonPill is Owned {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error ZeroAmount();
    error PriceSourceRequired();
    error PriceDecimalsRequired();
    error DiscountRequiredWithOracle();
    error InvalidDiscount();
    error InvalidPaymentAsset();
    error PaymentAssetRequired();
    error NotWhitelisted();
    error InvalidOraclePrice();
    error StaleOraclePrice();
    error SlippageExceeded();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event WhitelistUpdated(address indexed user, bool whitelisted);
    event PaymentAssetAdded(address indexed asset, address indexed oracle);
    event PaymentAssetRemoved(address indexed asset);
    event PriceUpdated(uint256 price);
    event DiscountUpdated(uint16 discountBP);
    event MaxOracleAgeUpdated(uint32 maxOracleAge);
    event Redeemed(address indexed user, address indexed paymentAsset, uint256 amountPaid, uint256 tokensOut);
    event Withdrawn(address indexed asset, uint256 amount);
    event Swept(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    /// @notice A payment asset accepted by the pill. Without an oracle the
    /// asset is assumed to be a stablecoin holding a 1:1 USD peg.
    struct PaymentAsset {
        AggregatorV3Interface oracle;
        uint8 assetDecimals;
        uint8 oracleDecimals;
        bool enabled;
    }

    struct Config {
        address token;
        address tokenOracle; // optional if price != 0
        address treasury;
        uint256 price; // optional if tokenOracle is set
        uint8 priceDecimals; // required when price is the only source
        uint16 discountBP; // required when tokenOracle is set
        uint32 maxOracleAge;
        address[] paymentAssets;
        address[] paymentOracles; // zero address => assumed 1:1 USD peg
        address[] whitelist;
    }

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Treasury token being sold at a discount.
    ERC20 public immutable token;

    /// @notice Recipient of sale proceeds and swept funds.
    address public immutable treasury;

    /// @notice USD feed for `token`. Optional when a manual `price` is maintained.
    AggregatorV3Interface public immutable tokenOracle;

    /// @notice Decimals of the token price, whether manual or oracle-provided.
    uint8 public immutable priceDecimals;

    uint8 internal immutable tokenDecimals;

    uint256 internal constant BPS = 10_000;
    uint256 internal constant WAD = 1e18;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Manual token price with `priceDecimals` decimals.
    /// Non-zero overrides `tokenOracle`; zero requires `tokenOracle` to be set.
    uint256 public price;

    /// @notice Basis points discounted from the token price.
    uint16 public discountBP;

    /// @notice Oldest acceptable oracle update; anything older reverts redeems.
    uint32 public maxOracleAge;

    /// @notice Accounts allowed to redeem.
    mapping(address => bool) public isWhitelisted;

    /// @notice Assets accepted as payment.
    mapping(ERC20 => PaymentAsset) public paymentAssets;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Config memory config) Owned(msg.sender) {
        _validateConfig(config);

        if (config.tokenOracle != address(0)) {
            priceDecimals = AggregatorV3Interface(config.tokenOracle).decimals();
        } else {
            priceDecimals = config.priceDecimals;
        }

        token = ERC20(config.token);
        tokenOracle = AggregatorV3Interface(config.tokenOracle);
        treasury = config.treasury;
        discountBP = config.discountBP;
        maxOracleAge = config.maxOracleAge;

        tokenDecimals = ERC20(config.token).decimals();

        if (config.price != 0) {
            price = config.price;
            emit PriceUpdated(config.price);
        }

        for (uint256 i = 0; i < config.paymentAssets.length; ++i) {
            _addPaymentAsset(ERC20(config.paymentAssets[i]), AggregatorV3Interface(config.paymentOracles[i]));
        }

        for (uint256 i = 0; i < config.whitelist.length; ++i) {
            isWhitelisted[config.whitelist[i]] = true;
            emit WhitelistUpdated(config.whitelist[i], true);
        }
    }

    function _validateConfig(Config memory config) internal pure {
        if (config.token == address(0) || config.treasury == address(0)) revert ZeroAddress();
        if (config.tokenOracle == address(0) && config.price == 0) revert PriceSourceRequired();
        if (config.discountBP >= BPS) revert InvalidDiscount();
        if (config.maxOracleAge == 0) revert ZeroAmount();
        if (config.paymentAssets.length == 0 || config.paymentAssets.length != config.paymentOracles.length) {
            revert PaymentAssetRequired();
        }
        // An oracle reports market price, so a pill without a discount would
        // sell at market — pointless. Require one upfront. Without an oracle,
        // the decimals of the manual price must be explicit.
        if (config.tokenOracle != address(0) && config.discountBP == 0) revert DiscountRequiredWithOracle();
        if (config.tokenOracle == address(0) && config.priceDecimals == 0) revert PriceDecimalsRequired();
    }

    /*//////////////////////////////////////////////////////////////
                             ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setWhitelisted(address user, bool whitelisted) public onlyOwner {
        isWhitelisted[user] = whitelisted;

        emit WhitelistUpdated(user, whitelisted);
    }

    function setWhitelistedBatch(address[] calldata users, bool whitelisted) external onlyOwner {
        for (uint256 i = 0; i < users.length; ++i) {
            setWhitelisted(users[i], whitelisted);
        }
    }

    /// @notice Accept `asset` as payment, valued through `oracle`, or
    /// assumed 1:1 USD-pegged when `oracle` is the zero address.
    function addPaymentAsset(ERC20 asset, AggregatorV3Interface oracle) external onlyOwner {
        _addPaymentAsset(asset, oracle);
    }

    function removePaymentAsset(ERC20 asset) external onlyOwner {
        if (!paymentAssets[asset].enabled) revert InvalidPaymentAsset();

        delete paymentAssets[asset];

        emit PaymentAssetRemoved(address(asset));
    }

    /// @notice Update the manual price, quoted with `priceDecimals` decimals.
    /// Setting zero falls back to the oracle and requires one to be configured.
    function setPrice(uint256 newPrice) external onlyOwner {
        if (newPrice == 0 && address(tokenOracle) == address(0)) revert PriceSourceRequired();

        price = newPrice;

        emit PriceUpdated(newPrice);
    }

    function setDiscount(uint16 newDiscountBP) external onlyOwner {
        if (newDiscountBP >= BPS) revert InvalidDiscount();

        discountBP = newDiscountBP;

        emit DiscountUpdated(newDiscountBP);
    }

    function setMaxOracleAge(uint32 newMaxOracleAge) external onlyOwner {
        if (newMaxOracleAge == 0) revert ZeroAmount();

        maxOracleAge = newMaxOracleAge;

        emit MaxOracleAgeUpdated(newMaxOracleAge);
    }

    function _addPaymentAsset(ERC20 asset, AggregatorV3Interface oracle) internal {
        // The treasury token cannot double as a payment asset, and payment
        // assets must expose decimals (also implies the address has code).
        if (address(asset) == address(0) || address(asset) == address(token)) revert InvalidPaymentAsset();

        // Deploy-time/owner-only registration over a short owner-provided list.
        // slither-disable-next-line calls-loop
        paymentAssets[asset] = PaymentAsset({
            oracle: oracle,
            assetDecimals: asset.decimals(),
            oracleDecimals: address(oracle) == address(0) ? 0 : oracle.decimals(),
            enabled: true
        });

        emit PaymentAssetAdded(address(asset), address(oracle));
    }

    /*//////////////////////////////////////////////////////////////
                           TREASURY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Push sale proceeds of `asset` to the treasury.
    /// Deliberately permissionless: proceeds have only one valid
    /// destination. The treasury token itself is excluded so nobody can
    /// defuse the pill mid-sale.
    function withdraw(ERC20 asset) external {
        if (address(asset) == address(token)) revert InvalidPaymentAsset();

        uint256 balance = asset.balanceOf(address(this));
        // Empty-balance short circuit; nothing attacker-influenced is compared.
        // slither-disable-next-line incorrect-equality
        if (balance == 0) return;

        asset.safeTransfer(treasury, balance);

        emit Withdrawn(address(asset), balance);
    }

    /// @notice Recover unsold treasury tokens once the pill has served its
    /// purpose. Owner-gated so nobody can defuse the pill mid-sale, but
    /// funds can only ever reach the treasury.
    function sweep() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        // slither-disable-next-line incorrect-equality
        if (balance == 0) return;

        token.safeTransfer(treasury, balance);

        emit Swept(balance);
    }

    /*//////////////////////////////////////////////////////////////
                             USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Buy treasury tokens at the discounted price.
    /// @param paymentAsset Registered asset to pay with (must be approved).
    /// @param amount Amount of `paymentAsset` to spend.
    /// @param minTokensOut Minimum tokens acceptable; guards against price
    /// moves between submission and execution.
    function redeem(ERC20 paymentAsset, uint256 amount, uint256 minTokensOut) external returns (uint256 tokensOut) {
        if (!isWhitelisted[msg.sender]) revert NotWhitelisted();
        if (amount == 0) revert ZeroAmount();

        tokensOut = previewRedeem(paymentAsset, amount);
        if (tokensOut == 0) revert ZeroAmount();
        if (tokensOut < minTokensOut) revert SlippageExceeded();

        paymentAsset.safeTransferFrom(msg.sender, address(this), amount);
        token.safeTransfer(msg.sender, tokensOut);

        emit Redeemed(msg.sender, address(paymentAsset), amount, tokensOut);
    }

    /// @notice Tokens received for a given payment at current prices.
    function previewRedeem(ERC20 paymentAsset, uint256 amount) public view returns (uint256) {
        PaymentAsset memory asset = paymentAssets[paymentAsset];
        if (!asset.enabled) revert InvalidPaymentAsset();

        uint256 usdWad;
        if (address(asset.oracle) == address(0)) {
            usdWad = amount.mulDivDown(WAD, 10 ** asset.assetDecimals);
        } else {
            uint256 assetUsd = _readOracle(asset.oracle);
            usdWad = amount.mulDivDown(assetUsd, 10 ** asset.oracleDecimals).mulDivDown(WAD, 10 ** asset.assetDecimals);
        }
        return usdWad.mulDivDown(10 ** priceDecimals, discountedPrice()).mulDivDown(10 ** tokenDecimals, WAD);
    }

    /// @notice Current token price after discount, with `priceDecimals` decimals.
    function discountedPrice() public view returns (uint256) {
        uint256 tokenPrice = price != 0 ? price : _readOracle(tokenOracle);
        uint256 discounted = tokenPrice.mulDivDown(BPS - discountBP, BPS);
        if (discounted == 0) revert InvalidOraclePrice();
        return discounted;
    }

    function _readOracle(AggregatorV3Interface oracle) internal view returns (uint256) {
        // roundId/answeredInRound checks are deprecated by Chainlink since
        // OCR; staleness is enforced through updatedAt below.
        // slither-disable-next-line unused-return
        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
        if (answer <= 0) revert InvalidOraclePrice();
        // Staleness bounds are hours, far beyond timestamp manipulation range.
        // slither-disable-next-line timestamp
        if (block.timestamp - updatedAt > maxOracleAge) revert StaleOraclePrice();
        // casting to 'uint256' is safe because answer is checked positive above
        // forge-lint: disable-next-line(unsafe-typecast)
        return uint256(answer);
    }
}
