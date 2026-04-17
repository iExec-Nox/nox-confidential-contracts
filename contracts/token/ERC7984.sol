// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC7984Optimized} from "./ERC7984Optimized.sol";

/**
 * @dev The default implementation of {IERC7984}.
 */
abstract contract ERC7984 is ERC7984Optimized {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984Optimized(name, symbol, contractURI) {}
}
