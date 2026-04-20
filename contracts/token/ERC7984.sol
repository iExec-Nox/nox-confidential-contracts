// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Base} from "./ERC7984Base.sol";

/**
 * @dev Reference implementation for {IERC7984} using optimized Nox primitives.
 */
abstract contract ERC7984 is ERC7984Base {
    constructor(string memory name, string memory symbol, string memory contractURI) {
        __ERC7984Base_init(name, symbol, contractURI);
    }

    /// @inheritdoc ERC7984Base
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        transferred = _updateWithOptimizedPrimitives(from, to, amount);
    }
}
