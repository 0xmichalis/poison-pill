//SPDX-License-Identifier: Anti-996 License
pragma solidity ^0.8.10;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC", 6) {}

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
