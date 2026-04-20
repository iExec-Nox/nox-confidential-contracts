// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20ToERC7984Wrapper} from "../../interfaces/IERC20ToERC7984Wrapper.sol";
import {ERC20ToERC7984WrapperRaw} from "../../token/extensions/ERC20ToERC7984WrapperRaw.sol";
import {ERC20ToERC7984Wrapper} from "../../token/extensions/ERC20ToERC7984Wrapper.sol";
import {ERC20ToERC7984WrapperRawUpgradeable} from "../../upgradeable/ERC20ToERC7984WrapperRawUpgradeable.sol";
import {ERC20ToERC7984WrapperUpgradeable} from "../../upgradeable/ERC20ToERC7984WrapperUpgradeable.sol";

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
 * @dev Common interface for all {ERC20ToERC7984Wrapper} test implementations (raw, optimized).
 */
interface WrapperTestMock is IERC20ToERC7984Wrapper, IERC1363Receiver {}

/// @dev Implementation of {ERC20ToERC7984WrapperRaw} for testing.
contract ERC20ToERC7984WrapperRawMock is WrapperTestMock, ERC20ToERC7984WrapperRaw {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984WrapperRaw(name, symbol, contractURI, underlying) {}
}

/// @dev Implementation of {ERC20ToERC7984Wrapper} for testing.
contract ERC20ToERC7984WrapperMock is WrapperTestMock, ERC20ToERC7984Wrapper {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC20ToERC7984Wrapper(name, symbol, contractURI, underlying) {}
}

/// @dev Implementation of {ERC20ToERC7984WrapperRawUpgradeable} for testing.
contract ERC20ToERC7984WrapperRawUpgradeableMock is
    WrapperTestMock,
    ERC20ToERC7984WrapperRawUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 underlying) ERC20ToERC7984WrapperRawUpgradeable(underlying) {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external initializer {
        __ERC20ToERC7984WrapperRaw_init(name, symbol, contractURI);
    }
}

/// @dev Implementation of {ERC20ToERC7984WrapperUpgradeable} for testing.
contract ERC20ToERC7984WrapperUpgradeableMock is WrapperTestMock, ERC20ToERC7984WrapperUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 underlying) ERC20ToERC7984WrapperUpgradeable(underlying) {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external initializer {
        __ERC20ToERC7984Wrapper_init(name, symbol, contractURI);
    }
}
