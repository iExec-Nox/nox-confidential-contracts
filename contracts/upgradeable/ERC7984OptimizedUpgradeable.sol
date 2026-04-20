// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (contracts/token/ERC7984/ERC7984.sol)
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Base} from "../token/ERC7984Base.sol";

/**
 * @notice Upgradeable version of {ERC7984Optimized}.
 */
abstract contract ERC7984OptimizedUpgradeable is ERC7984Base, Initializable {
    function __ERC7984Optimized_init(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) internal onlyInitializing {
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
