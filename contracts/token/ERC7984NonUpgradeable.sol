// SPDX-License-Identifier: MIT
// Inspired by OpenZeppelin Contracts (contracts/token/ERC7984/ERC7984.sol)
pragma solidity ^0.8.28;

import {ERC7984Base, ERC7984Storage} from "./ERC7984Base.sol";

// TODO change filename to ERC7984.sol
abstract contract ERC7984 is ERC7984Base {
    ERC7984Storage private _erc7984Storage;
    function _getERC7984Storage() internal view override returns (ERC7984Storage storage $) {
        return _erc7984Storage;
    }

    constructor(string memory name_, string memory symbol_, string memory contractURI_) {
        ERC7984Storage storage $ = _getERC7984Storage();
        $._name = name_;
        $._symbol = symbol_;
        $._contractURI = contractURI_;
    }
}
