// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984} from "../../token/ERC7984.sol";

/// @dev Concrete implementation of ERC7984 for testing purposes.
contract ERC7984Mock is ERC7984, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address owner_
    ) ERC7984(name_, symbol_, contractURI_) Ownable(owner_) {}

    function mint(address to, euint256 amount) external returns (euint256) {
        return _mint(to, amount);
    }

    function burn(address from, euint256 amount) external returns (euint256) {
        return _burn(from, amount);
    }
}
