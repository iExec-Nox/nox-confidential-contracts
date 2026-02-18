// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {euint64} from "encrypted-types/EncryptedTypes.sol";
import {ERC7984} from "../../token/ERC7984.sol";

/// @dev Concrete implementation of ERC7984 for testing purposes.
contract ERC7984Mock is ERC7984 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address owner_
    ) ERC7984(name_, symbol_, contractURI_, owner_) {}

    function mint(address to, euint64 amount) external returns (euint64) {
        return _mint(to, amount);
    }

    function burn(address from, euint64 amount) external returns (euint64) {
        return _burn(from, amount);
    }
}
