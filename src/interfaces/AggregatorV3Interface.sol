// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

/// @notice Chainlink-compatible price feed interface.
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
