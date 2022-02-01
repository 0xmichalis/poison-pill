//SPDX-License-Identifier: Anti-996 License
pragma solidity ^0.8.10;

interface VM {
    function deal(address who, uint256 newBalance) external;
    function expectRevert(bytes calldata) external;
    function prank(address sender) external;
    function startPrank(address) external;
    function stopPrank() external;
}
