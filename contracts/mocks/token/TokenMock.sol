// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "../../interfaces/IERC7984.sol";
import {ERC7984} from "../../token/ERC7984.sol";
import {ERC7984Advanced} from "../../token/ERC7984Advanced.sol";
import {ERC7984Upgradeable} from "../../token/ERC7984Upgradeable.sol";
import {ERC7984UpgradeableAdvanced} from "../../token/ERC7984UpgradeableAdvanced.sol";

/**
 * @dev Common interface for all ERC7984 test implementations (basic, advanced).
 */
interface TokenMock is IERC7984 {
    function mint(address to, euint256 amount) external returns (euint256);
    function burn(address from, euint256 amount) external returns (euint256);
    function transfer(address from, address to, euint256 amount) external returns (euint256);
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

/**
 * @dev Mock implementation of {ERC7984UpgradeableAdvanced}.
 */
contract ERC7984UpgradeableAdvancedMock is TokenMock, ERC7984UpgradeableAdvanced {
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
