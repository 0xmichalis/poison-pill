//SPDX-License-Identifier: Anti-996 License
pragma solidity ^0.8.10;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}
