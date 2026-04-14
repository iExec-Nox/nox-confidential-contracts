// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC7984AdvancedPrimitives} from "./base/ERC7984AdvancedPrimitives.sol";

// TODO Find a better name for this contract.
/**
 * @dev Reference implementation for {ERC7984} using advanced Nox primitives.
 * @dev See {ERC7984}.
 */
abstract contract ERC7984Advanced is ERC7984AdvancedPrimitives {
    constructor(string memory name, string memory symbol, string memory contractURI) {
        __ERC7984Base_init(name, symbol, contractURI);
    }
}
