// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function balanceOf(address tokenOwner) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address delegate, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}
