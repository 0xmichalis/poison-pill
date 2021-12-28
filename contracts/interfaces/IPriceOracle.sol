//SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.10;

interface IPriceOracle {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (uint256);
}