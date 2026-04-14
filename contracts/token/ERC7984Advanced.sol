// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    Nox,
    euint256,
    externalEuint256,
    ebool
} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {ERC7984BaseAdvanced} from "./ERC7984BaseAdvanced.sol";

// TODO Find a better name for this contract.
/**
 * @dev Reference implementation for {ERC7984} using advanced Nox primitives.
 * @dev See {ERC7984}.
 */
abstract contract ERC7984Advanced is ERC7984BaseAdvanced {
    constructor(string memory name, string memory symbol, string memory contractURI) {
        __ERC7984Base_init(name, symbol, contractURI);
    }
}
