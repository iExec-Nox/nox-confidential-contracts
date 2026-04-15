// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20ToERC7984Wrapper} from "./ERC20ToERC7984Wrapper.sol";

/**
 * @dev Upgradeable implementation of {ERC20ToERC7984Wrapper}.
 */
abstract contract ERC20ToERC7984WrapperUpgradeable is ERC20ToERC7984Wrapper, Initializable {
    // The constructor is required here to initialize immutable variables.
    constructor(IERC20 underlying) ERC20ToERC7984Wrapper(underlying) {}

    // TODO check if this is required.
    function __ERC20ToERC7984WrapperUpgradeable_init(IERC20 underlying) internal onlyInitializing {}
}
