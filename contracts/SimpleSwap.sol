// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    // Implement core logic here

    // naming tokenA will cause func getTokenA return address(0), since the return param named tokenA
    address public aToken;
    address public bToken;

    uint256 private _reserveA;
    uint256 private _reserveB;

    constructor(address _token0, address _token1) ERC20("LP token", "LPT") {
        require(_token0 != address(0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_token1 != address(0), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_token0 != _token1, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");

        (address _tokenA, address _tokenB) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);
        aToken = _tokenA;
        bToken = _tokenB;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        return 0;
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        return (0, 0, 0);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        return (0, 0);
    }

    function getReserves() external view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    /// @notice Get the address of tokenA
    /// @return tokenA The address of tokenA
    function getTokenA() external view returns (address tokenA) {
        return aToken;
    }

    /// @notice Get the address of tokenB
    /// @return tokenB The address of tokenB
    function getTokenB() external view returns (address tokenB) {
        return bToken;
    }
}
