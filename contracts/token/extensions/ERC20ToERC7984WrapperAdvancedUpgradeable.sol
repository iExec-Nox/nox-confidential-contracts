// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20ToERC7984WrapperAdvanced} from "./ERC20ToERC7984WrapperAdvanced.sol";

/**
 * @dev Upgradeable implementation of {ERC20ToERC7984WrapperAdvanced}.
 */
abstract contract ERC20ToERC7984WrapperAdvancedUpgradeable is
    ERC20ToERC7984WrapperAdvanced,
    Initializable
{
    // The constructor is required here to initialize immutable variables.
    constructor(IERC20 underlying) ERC20ToERC7984WrapperAdvanced(underlying) {}

    // TODO check if this is required.
    function __ERC20ToERC7984WrapperAdvancedUpgradeable_init() internal onlyInitializing {}
}
