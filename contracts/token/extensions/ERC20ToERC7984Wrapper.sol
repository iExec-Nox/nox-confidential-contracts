// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC20ToERC7984WrapperOptimized} from "./ERC20ToERC7984WrapperOptimized.sol";

/**
 * @dev The default implementation of {IERC20ToERC7984Wrapper}.
 */
abstract contract ERC20ToERC7984Wrapper is ERC20ToERC7984WrapperOptimized {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984WrapperOptimized(name, symbol, contractURI, underlying) {}
}
