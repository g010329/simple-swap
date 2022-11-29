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

    uint256 private _unlocked = 1;

    modifier lock() {
        require(_unlocked == 1, "SimpleSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    constructor(address _token0, address _token1) ERC20("LP token", "LPT") {
        require(_token0 != address(0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_token1 != address(0), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_token0 != _token1, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");

        (address _tokenA, address _tokenB) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);
        aToken = _tokenA;
        bToken = _tokenB;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external lock returns (uint256 amountOut) {
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

        _updateReserves();

        emit Swap(_msgSender(), tokenIn, tokenOut, amountIn, amountOut);
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external lock returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
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

        _updateReserves();
        _mint(_msgSender, liquidity);

        emit AddLiquidity(_msgSender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external lock returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        address _msgSender = _msgSender();
        uint256 _totalSupply = totalSupply();

        // FIXME: AssertionError: Expected the balances of TokenB tokens for 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 to change by 10000000000000000000,-10000000000000000000, respectively, but they changed by 0,0
        // amountA = (liquidity / _totalSupply) * _reserveA;
        // amountB = (liquidity / _totalSupply) * _reserveB;
        amountA = (liquidity * _reserveA) / _totalSupply;
        amountB = (liquidity * _reserveB) / _totalSupply;

        ERC20(aToken).transfer(_msgSender, amountA);
        ERC20(bToken).transfer(_msgSender, amountB);

        _transfer(_msgSender, address(this), liquidity);
        _burn(address(this), liquidity);

        _updateReserves();

        emit RemoveLiquidity(_msgSender, amountA, amountB, liquidity);
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

    function _updateReserves() private {
        _reserveA = ERC20(aToken).balanceOf(address(this));
        _reserveB = ERC20(bToken).balanceOf(address(this));
    }
}
