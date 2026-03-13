// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "../../token/ERC7984.sol";
import {ERC7984} from "../../token/ERC7984.sol";
import {ERC7984Advanced} from "../../token/ERC7984Advanced.sol";

/**
 * @dev Common interface for all ERC7984 test implementations (basic, advanced).
 */
interface IERC7984TestableMock is IERC7984 {
    function mint(address to, euint256 amount) external returns (euint256);
    function burn(address from, euint256 amount) external returns (euint256);
    function transfer(address from, address to, euint256 amount) external returns (euint256);
}

/**
 * @dev Implementation of {ERC7984} for testing purposes.
 */
contract ERC7984Mock is IERC7984TestableMock, ERC7984 {
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
 * @dev Implementation of {ERC7984Advanced} for testing purposes.
 */
contract ERC7984AdvancedMock is IERC7984TestableMock, ERC7984Advanced {
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
