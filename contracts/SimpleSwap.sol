// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
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
        require(tokenIn != address(0) && (tokenIn == aToken || tokenIn == bToken), "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut != address(0) && (tokenOut == aToken || tokenOut == bToken), "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenOut != tokenIn, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        if (_reserveA == 0 || _reserveB == 0 || totalSupply() == 0) {
            amountOut = 0;
        } else {
            amountOut = tokenIn == aToken
                ? (amountIn * _reserveB) / (_reserveA + amountIn) // SimpleSwap.spec.ts line: 317
                : (amountIn * _reserveA) / (_reserveB + amountIn);
        }
        require(amountOut > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        ERC20(tokenIn).transferFrom(_msgSender(), address(this), amountIn);
        ERC20(tokenOut).approve(address(this), amountOut);
        ERC20(tokenOut).transferFrom(address(this), _msgSender(), amountOut);

        _updateReserve();

        emit Swap(_msgSender(), tokenIn, tokenOut, amountIn, amountOut);
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint256 _totalSupply = totalSupply();
        address _msgSender = _msgSender();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountAIn * amountBIn);

            amountA = amountAIn;
            amountB = amountBIn;
        } else {
            liquidity = Math.min((amountAIn * _totalSupply) / _reserveA, (amountBIn * _totalSupply) / _reserveB);

            amountA = (liquidity * _reserveA) / _totalSupply;
            amountB = (liquidity * _reserveB) / _totalSupply;
        }

        ERC20(aToken).transferFrom(_msgSender, address(this), amountA);
        ERC20(bToken).transferFrom(_msgSender, address(this), amountB);

        _updateReserve();
        _mint(_msgSender, liquidity);

        emit AddLiquidity(_msgSender, amountA, amountB, liquidity);
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
        tokenA = aToken;
    }

    /// @notice Get the address of tokenB
    /// @return tokenB The address of tokenB
    function getTokenB() external view returns (address tokenB) {
        tokenB = bToken;
    }

    function _updateReserve() private {
        _reserveA = ERC20(aToken).balanceOf(address(this));
        _reserveB = ERC20(bToken).balanceOf(address(this));
    }
}
