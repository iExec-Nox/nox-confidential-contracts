// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (contracts/token/ERC7984/ERC7984.sol)
pragma solidity ^0.8.28;

import {ERC7984BasicPrimitives} from "./ERC7984BasicPrimitives.sol";

abstract contract ERC7984 is ERC7984BasicPrimitives {
    constructor(string memory name, string memory symbol, string memory contractURI) {
        __ERC7984Base_init(name, symbol, contractURI);
    }
}
