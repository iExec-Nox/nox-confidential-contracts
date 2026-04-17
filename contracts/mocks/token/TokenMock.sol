// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "../../interfaces/IERC7984.sol";
import {ERC7984Raw} from "../../token/ERC7984Raw.sol";
import {ERC7984Advanced} from "../../token/ERC7984Advanced.sol";
import {ERC7984RawUpgradeable} from "../../token/ERC7984RawUpgradeable.sol";
import {ERC7984AdvancedUpgradeable} from "../../token/ERC7984AdvancedUpgradeable.sol";

/**
 * @dev Common interface for all ERC7984 test implementations (raw, advanced).
 */
interface TokenMock is IERC7984 {
    function mint(address to, euint256 amount) external returns (euint256);
    function burn(address from, euint256 amount) external returns (euint256);
    function transfer(address from, address to, euint256 amount) external returns (euint256);
}

/**
 * @dev Mock implementation of {ERC7984Raw}.
 */
contract ERC7984RawMock is TokenMock, ERC7984Raw {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984Raw(name, symbol, contractURI) {}

    function mint(address to, euint256 amount) external override returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external override returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}

/**
 * @dev Mock implementation of {ERC7984Advanced}.
 */
contract ERC7984AdvancedMock is TokenMock, ERC7984Advanced {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984Advanced(name, symbol, contractURI) {}

    function mint(address to, euint256 amount) external override returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external override returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}

/**
 * @dev Mock implementation of {ERC7984RawUpgradeable}.
 */
contract ERC7984RawUpgradeableMock is TokenMock, ERC7984RawUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external initializer {
        __ERC7984Raw_init(name, symbol, contractURI);
    }

    function mint(address to, euint256 amount) external override returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external override returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}

/**
 * @dev Mock implementation of {ERC7984AdvancedUpgradeable}.
 */
contract ERC7984AdvancedUpgradeableMock is TokenMock, ERC7984AdvancedUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external initializer {
        __ERC7984Advanced_init(name, symbol, contractURI);
    }

    function mint(address to, euint256 amount) external override returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external override returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(
        address from,
        address to,
        euint256 amount
    ) external override returns (euint256) {
        return _transfer(from, to, amount);
    }
}
