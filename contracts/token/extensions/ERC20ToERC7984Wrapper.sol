// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Confidential Contracts (contracts/token/ERC7984/extensions/ERC7984ERC20Wrapper.sol)
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984} from "../ERC7984.sol";
import {ERC7984Base} from "../base/ERC7984Base.sol";
import {ERC20ToERC7984WrapperBase} from "./ERC20ToERC7984WrapperBase.sol";

abstract contract ERC20ToERC7984Wrapper is ERC7984, ERC20ToERC7984WrapperBase {
    constructor(IERC20 underlying_) ERC20ToERC7984WrapperBase(underlying_) {}

    /// @inheritdoc ERC7984Base
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override(ERC7984Base, ERC7984) returns (euint256 transferred) {
        if (from == address(0)) _checkConfidentialTotalSupply();
        return ERC7984._update(from, to, amount);
    }

    /// @inheritdoc ERC20ToERC7984WrapperBase
    function decimals()
        public
        view
        override(ERC7984Base, ERC20ToERC7984WrapperBase)
        returns (uint8)
    {
        return ERC20ToERC7984WrapperBase.decimals();
    }

    /// @inheritdoc ERC7984Base
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC7984Base, ERC20ToERC7984WrapperBase) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
