// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "../../interfaces/IERC7984.sol";
import {ERC7984Raw} from "../../token/ERC7984Raw.sol";
import {ERC7984} from "../../token/ERC7984.sol";
import {ERC7984RawUpgradeable} from "../../upgradeable/ERC7984RawUpgradeable.sol";
import {ERC7984Upgradeable} from "../../upgradeable/ERC7984Upgradeable.sol";

/**
 * @dev Common interface for all ERC7984 test implementations (raw, optimized).
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
 * @dev Mock implementation of {ERC7984}.
 */
contract ERC7984Mock is TokenMock, ERC7984 {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984(name, symbol, contractURI) {}

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
 * @dev Mock implementation of {ERC7984Upgradeable}.
 */
contract ERC7984UpgradeableMock is TokenMock, ERC7984Upgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) external initializer {
        __ERC7984_init(name, symbol, contractURI);
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
