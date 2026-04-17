// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (contracts/token/ERC7984/ERC7984.sol)
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Base} from "./ERC7984Base.sol";

/**
 * @dev Reference implementation for {IERC7984} using raw Nox primitives.
 */
abstract contract ERC7984Raw is ERC7984Base {
    constructor(string memory name, string memory symbol, string memory contractURI) {
        __ERC7984Base_init(name, symbol, contractURI);
    }

    /// @inheritdoc ERC7984Base
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        transferred = _updateWithBasicPrimitives(from, to, amount);
    }
}
