// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (contracts/token/ERC7984/ERC7984.sol)
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC7984Base, ERC7984Storage} from "./ERC7984Base.sol";

abstract contract ERC7984 is ERC7984Base, Initializable {
    function _getERC7984Storage() internal pure override returns (ERC7984Storage storage $) {
        assembly {
            // keccak256(abi.encode(uint256(keccak256("nox.storage.ERC7984")) - 1)) & ~bytes32(uint256(0xff))
            $.slot := 0xb419a3e8264d03c5da9315fb9617f069307274561d78c35809e10a1cfb715600
        }
    }

    function __ERC7984_init(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        __ERC7984_init_unchained(name_, symbol_, contractURI_);
    }

    function __ERC7984_init_unchained(
        string memory name_,
        string memory symbol_,
        string memory contractURI_
    ) internal onlyInitializing {
        ERC7984Storage storage $ = _getERC7984Storage();
        $._name = name_;
        $._symbol = symbol_;
        $._contractURI = contractURI_;
    }
}
