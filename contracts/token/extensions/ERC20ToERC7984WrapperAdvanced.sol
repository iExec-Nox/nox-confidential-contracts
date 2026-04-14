// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Base} from "../base/ERC7984Base.sol";
import {ERC7984AdvancedPrimitives} from "../base/ERC7984AdvancedPrimitives.sol";
import {ERC7984Advanced} from "../ERC7984Advanced.sol";
import {ERC20ToERC7984WrapperBase} from "./ERC20ToERC7984WrapperBase.sol";

/**
 * @dev Implementation of {ERC20ToERC7984Wrapper} using advanced Nox primitives.
 * See {ERC20ToERC7984Wrapper}.
 */
abstract contract ERC20ToERC7984WrapperAdvanced is ERC7984Advanced, ERC20ToERC7984WrapperBase {
    constructor(IERC20 underlying) ERC20ToERC7984WrapperBase(underlying) {}

    /// @inheritdoc ERC7984AdvancedPrimitives
    function _update(
        address from,
        address to,
        euint256 amount
    ) internal virtual override(ERC7984Base, ERC7984AdvancedPrimitives) returns (euint256) {
        if (from == address(0)) _checkConfidentialTotalSupply();
        return super._update(from, to, amount);
    }

    /// @inheritdoc ERC7984Base
    function decimals()
        public
        view
        virtual
        override(ERC7984Base, ERC20ToERC7984WrapperBase)
        returns (uint8)
    {
        return ERC20ToERC7984WrapperBase.decimals();
    }

    /// @inheritdoc ERC7984Base
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC7984Base, ERC20ToERC7984WrapperBase) returns (bool) {
        return ERC20ToERC7984WrapperBase.supportsInterface(interfaceId);
    }
}
