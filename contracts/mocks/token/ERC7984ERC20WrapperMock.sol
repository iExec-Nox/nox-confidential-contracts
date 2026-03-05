// SPDX-License-Identifier: Apache-2.0
// Inspired by OpenZeppelin Confidential Contracts (token/ERC7984/extensions/ERC7984ERC20Wrapper.sol)
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC7984} from "../../token/ERC7984.sol";
import {ERC7984ERC20Wrapper} from "../../token/extensions/ERC7984ERC20Wrapper.sol";

/// @dev Minimal ERC-20 with a public mint function, used for testing.
contract ERC20Mock is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @dev Concrete implementation of ERC7984ERC20Wrapper for testing.
contract ERC7984ERC20WrapperMock is ERC7984ERC20Wrapper {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        IERC20 underlying_
    ) ERC7984(name_, symbol_, contractURI_) ERC7984ERC20Wrapper(underlying_) {}
}
