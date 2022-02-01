//SPDX-License-Identifier: Anti-996 License
pragma solidity ^0.8.10;

contract TestPriceOracle {
    uint256 private _price;
    uint8 private _decimals;

    constructor(uint256 price, uint8 decimals_) {
        _price = price;
        _decimals = decimals_;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestAnswer() external view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price) external {
        _price = price;
    }
}