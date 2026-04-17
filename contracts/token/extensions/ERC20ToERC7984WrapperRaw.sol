// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC20ToERC7984WrapperBase} from "./ERC20ToERC7984WrapperBase.sol";

/**
 * @dev Implementation of {IERC20ToERC7984Wrapper} using raw Nox primitives.
 */
abstract contract ERC20ToERC7984WrapperRaw is ERC20ToERC7984WrapperBase {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984WrapperBase(underlying) {
        __ERC7984Base_init(name, symbol, contractURI);
    }

    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override returns (euint256 transferred) {
        transferred = _updateWithBasicPrimitives(from, to, amount);
    }
}
