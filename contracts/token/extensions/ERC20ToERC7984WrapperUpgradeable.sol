// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC20ToERC7984WrapperBase} from "./ERC20ToERC7984WrapperBase.sol";

/**
 * @dev Upgradeable implementation of {ERC20ToERC7984Wrapper}.
 */
abstract contract ERC20ToERC7984WrapperUpgradeable is ERC20ToERC7984WrapperBase, Initializable {
    // The constructor is required here to initialize immutable variables.
    constructor(IERC20 underlying) ERC20ToERC7984WrapperBase(underlying) {}

    function __ERC20ToERC7984WrapperUpgradeable_init(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) internal onlyInitializing {
        __ERC7984Base_init(name, symbol, contractURI);
    }

    /// @inheritdoc ERC20ToERC7984WrapperBase
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        transferred = _updateWithBasicPrimitives(from, to, amount);
    }
}
