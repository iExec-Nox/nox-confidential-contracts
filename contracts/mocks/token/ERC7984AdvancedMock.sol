// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984Advanced} from "../../token/ERC7984Advanced.sol";
import {IERC7984Mock} from "./IERC7984Mock.sol";

contract ERC7984AdvancedMock is IERC7984Mock, ERC7984Advanced {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984Advanced(name, symbol, contractURI) {}

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
