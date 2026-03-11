// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984} from "../../token/ERC7984.sol";

/// @dev Concrete implementation of ERC7984 for testing purposes.
contract ERC7984Mock is ERC7984 {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984(name, symbol, contractURI) {}

    function mint(address to, euint256 amount) external returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external returns (euint256) {
        return _burn(from, amount);
    }

    function transfer(address from, address to, euint256 amount) external returns (euint256) {
        return _transfer(from, to, amount);
    }
}
