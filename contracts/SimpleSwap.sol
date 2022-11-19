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
        return 0;
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint256 _totalSupply = totalSupply();
        uint256 _liquidity;
        uint256 _addedAmountAIn = amountAIn;
        uint256 _addedAmountBIn = amountBIn;
        address _msgSender = _msgSender();

        if (_totalSupply == 0) {
            // first time to add liquidity
            _liquidity = Math.sqrt(amountAIn * amountBIn);
        } else {
            // not first time to add liquidity
            _liquidity = Math.min((amountAIn * _totalSupply) / _reserveA, (amountBIn * _totalSupply) / _reserveB);

            _addedAmountAIn = (_liquidity * _reserveA) / _totalSupply;
            _addedAmountBIn = (_liquidity * _reserveB) / _totalSupply;
        }

        ERC20(aToken).transferFrom(_msgSender, address(this), _addedAmountAIn);
        ERC20(bToken).transferFrom(_msgSender, address(this), _addedAmountBIn);

        _updateReserve();
        _mint(_msgSender, _liquidity);

        emit AddLiquidity(_msgSender, _addedAmountAIn, _addedAmountBIn, _liquidity);

        return (_addedAmountAIn, _addedAmountBIn, _liquidity);
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
