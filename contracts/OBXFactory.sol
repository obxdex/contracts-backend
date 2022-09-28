// SPDX-License-Identifier: MIT
// ref: https://etherscan.io/address/0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f/advanced#code
pragma solidity ^0.8.11;

import "./OBXExchange.sol";

contract OBXFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "Token addresses are identical");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Token address cannot be null");
        require(getPair[token0][token1] == address(0), "Pair already exist");

        address _feeReceiver = 0x46656Be8b381aDAe1fF535fF9872B6485813BD7f;

        pair = address(new OBXExchange(tokenA, tokenB, _feeReceiver));

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        return pair;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}
