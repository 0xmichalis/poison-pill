//SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.10;

import { Auth, Authority } from "@rari-capital/solmate/src/auth/Auth.sol";
import { Trust } from "@rari-capital/solmate/src/auth/Trust.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";

// TODO: Limit how much each user can buy
contract PoisonPill is Auth, Trust {
    /************************************************
     *  VARIABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH contract address
    address public immutable WETH;

    /// @notice USDC contract address
    /// In code it is currently assumed that USDC will always
    /// hold its peg.
    address public immutable USDC;

    /// @notice ERC20 token to poison pill
    address public immutable token;

    /// @notice Owner of the funds to poison pill
    address public immutable treasury;

    /// @notice Oracle to get token price from
    address public immutable tokenOracle;

    /// @notice Oracle to get ETH price from
    address public immutable ethOracle;

    /// @notice Manual price, in case on-chain oracle price does not exist
    /// This can either be the market price of the token in which case
    /// discountBP needs to be specified to apply the price discount or in
    /// case discountBP is set to zero, this can track the discounted price.
    uint256 public price;

    /// @notice Basis points to discount from price
    uint16 public discountBP;

    /// @notice Decimals in the eth oracle response
    uint8 private ethOracleDecimals;

    /// @notice Decimals in the token
    uint8 private tokenDecimals;

    /// @notice Decimals in the token oracle response
    uint8 private tokenOracleDecimals;


    /************************************************
     *  EVENTS
     ***********************************************/

    /// @notice Event emitted when the price of the token is manually updated
    event PriceUpdated(uint256 price);

    /// @notice Event emitted when the discount is updated
    event DiscountUpdated(uint16 discountBP);


    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor(
        address _usdc,
        address _weth,
        address _token,
        address _ethOracle,
        address _tokenOracle,
        address _treasury,
        address[] memory _users,
        uint256 _price,
        uint8 _priceDecimals,
        uint16 _discountBP
    ) payable Auth(msg.sender, Authority(address(0))) Trust(address(0)) {
        require(_usdc != address(0), "!_usdc");
        require(_weth != address(0), "!_weth");
        require(_token != address(0), "!_token");
        require(_ethOracle != address(0), "!_ethOracle");
        require(_tokenOracle != address(0) || _price != 0, "Need one of _tokenOracle, _price");
        require(_tokenOracle == address(0) || _price == 0, "Only one of _tokenOracle, _price");
        if (_tokenOracle != address(0)) {
            // Need to have the discount percentage specified in case we can
            // retrieve the token price via the price oracle. This assumes the
            // used oracle returns the market price and not the target discounted
            // price.
            require(_discountBP != 0, "!_discountBP");
        }
        require(_discountBP <= 10000, "Invalid discount basis points");

        USDC = _usdc;
        WETH = _weth;
        token = _token;
        ethOracle = _ethOracle;
        tokenOracle = _tokenOracle;
        discountBP = _discountBP;
        treasury = _treasury;
        ethOracleDecimals = IPriceOracle(ethOracle).decimals();
        tokenDecimals = IERC20(token).decimals();
        if (_price == 0) {
            tokenOracleDecimals = IPriceOracle(tokenOracle).decimals();
        } else {
            price = _price;
            tokenOracleDecimals = _priceDecimals;
            emit PriceUpdated(_price);
        }
        unchecked {
            for (uint i = 0; i < _users.length; i++) {
                isTrusted[_users[i]] = true;
                emit UserTrustUpdated(_users[i], true);
            }
        }
    }


    /************************************************
     *  ADMIN FUNCTIONS
     ***********************************************/

    function setIsTrustedBatch(address[] memory _users, bool trusted) external requiresAuth {
        unchecked {
            for (uint i = 0; i < _users.length; i++) {
                setIsTrusted(_users[i], trusted);
            }
        }
    }

    function setIsTrusted(address user, bool trusted) public override requiresAuth {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    function setPrice(uint256 _price) external requiresAuth {
        price = _price;

        emit PriceUpdated(_price);
    }

    function setDiscount(uint16 _discountBP) external requiresAuth {
        require(_discountBP <= 10000, "Invalid discount basis points");

        discountBP = _discountBP;

        emit DiscountUpdated(_discountBP);
    }


    /************************************************
     *  TREASURY FUNCTIONS
     ***********************************************/

    /// @notice Withdraw all acquired funds back to the treasury
    /// On purpose left unguarded, anyone should be able to call it.
    function withdraw() external {
        uint256 ethBalance = IWETH(WETH).balanceOf(address(this));
        if (ethBalance != 0) {
            IWETH(WETH).transfer(treasury, ethBalance);
        }

        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
        if (usdcBalance != 0) {
            IERC20(USDC).transfer(treasury, usdcBalance);
        }
    }

    /************************************************
     *  USER FUNCTIONS
     ***********************************************/

    /// @notice Redeem tokens from the treasury in a discount to market price
    /// @param amount The amount of USDC or WETH the user is willing to spend
    /// @param isUSDC Whether the payment is in USDC or WETH
    function redeem(uint256 amount, bool isUSDC) external requiresTrust {
        // Determine token price
        uint256 oraclePrice;
        uint8 oracleDecimals = tokenOracleDecimals;
        if (price == 0) {
            oraclePrice = IPriceOracle(tokenOracle).latestAnswer();
        } else {
            // Notice that the price is maintained manually here
            // so there is no guarantee that it is actually below
            // market price.
            oraclePrice = price;
        }

        // Apply discount if provided
        if (discountBP != 0) {
            uint256 discount = oraclePrice * discountBP / 10000;
            oraclePrice -= discount;
        }

        // Exchange tokens for WETH or USDC
        // Note that the user needs to approve this amount of USDC/WETH
        // to spend before initiating the redeem.
        if (isUSDC) {
            // TODO: Make use of USDC price oracle
            // https://data.chain.link/ethereum/mainnet/stablecoins/usdc-usd
            uint8 stableDecimals = 6;
            uint256 tokenAmount = amount * (10 ** oracleDecimals) / oraclePrice;
            if (tokenDecimals > stableDecimals) {
                tokenAmount *= (10 ** (tokenDecimals - stableDecimals));
            } else if (tokenDecimals < stableDecimals) {
                tokenAmount /= (10 ** (stableDecimals - tokenDecimals));
            }
            IERC20(USDC).transferFrom(msg.sender, address(this), amount);
            IERC20(token).transfer(msg.sender, tokenAmount);
        } else {
            // TODO: Accept direct ETH payments
            uint256 ethPrice = IPriceOracle(ethOracle).latestAnswer();
            uint256 usdAmount = amount * ethPrice / (10 ** ethOracleDecimals);

            uint8 ethDecimals = 18;
            uint256 tokenAmount = usdAmount * (10 ** oracleDecimals) / oraclePrice;
            if (tokenDecimals > ethDecimals) {
                tokenAmount *= (10 ** (tokenDecimals - ethDecimals));
            } else if (tokenDecimals < ethDecimals) {
                tokenAmount /= (10 ** (ethDecimals - tokenDecimals));
            }
            IERC20(WETH).transferFrom(msg.sender, address(this), amount);
            IERC20(token).transfer(msg.sender, tokenAmount);
        }

    }
}
