// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20ToERC7984Wrapper} from "../../interfaces/IERC20ToERC7984Wrapper.sol";
import {ERC20ToERC7984Wrapper} from "../../token/extensions/ERC20ToERC7984Wrapper.sol";
import {ERC20ToERC7984WrapperAdvanced} from "../../token/extensions/ERC20ToERC7984WrapperAdvanced.sol";
import {ERC20ToERC7984WrapperUpgradeable} from "../../token/extensions/ERC20ToERC7984WrapperUpgradeable.sol";
import {ERC20ToERC7984WrapperAdvancedUpgradeable} from "../../token/extensions/ERC20ToERC7984WrapperAdvancedUpgradeable.sol";

/// @dev Minimal ERC-20 with a public mint function, used for testing.
contract ERC20Mock is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @dev Common interface for all {ERC20ToERC7984Wrapper} test implementations (basic, advanced).
 */
interface WrapperMock is IERC20ToERC7984Wrapper, IERC1363Receiver {}

/// @dev Implementation of {ERC20ToERC7984Wrapper} for testing.
contract ERC20ToERC7984WrapperMock is WrapperMock, ERC20ToERC7984Wrapper {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984Wrapper(underlying) {}
}

/// @dev Implementation of {ERC20ToERC7984WrapperAdvanced} for testing.
contract ERC20ToERC7984WrapperAdvancedMock is WrapperMock, ERC20ToERC7984WrapperAdvanced {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984WrapperAdvanced(underlying) {}
}

/// @dev Implementation of {ERC20ToERC7984WrapperUpgradeable} for testing.
contract ERC20ToERC7984WrapperUpgradeableMock is WrapperMock, ERC20ToERC7984WrapperUpgradeable {
    constructor(IERC20 underlying) ERC20ToERC7984WrapperUpgradeable(underlying) {
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC20ToERC7984WrapperUpgradeable_init();
    }
}

/// @dev Implementation of {ERC20ToERC7984WrapperAdvancedUpgradeable} for testing.
contract ERC20ToERC7984WrapperAdvancedUpgradeableMock is
    WrapperMock,
    ERC20ToERC7984WrapperAdvancedUpgradeable
{
    constructor(IERC20 underlying) ERC20ToERC7984WrapperAdvancedUpgradeable(underlying) {
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC20ToERC7984WrapperAdvancedUpgradeable_init();
    }
}
