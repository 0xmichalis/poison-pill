// SPDX-License-Identifier: Anti-996 License
pragma solidity 0.8.35;

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) { }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
