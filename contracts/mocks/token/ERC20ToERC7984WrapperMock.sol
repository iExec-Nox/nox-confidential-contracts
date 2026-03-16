// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20ToERC7984Wrapper} from "../../interfaces/IERC20ToERC7984Wrapper.sol";
import {ERC7984Advanced} from "../../token/ERC7984Advanced.sol";
import {ERC7984} from "../../token/ERC7984.sol";
import {ERC20ToERC7984Wrapper} from "../../token/extensions/ERC20ToERC7984Wrapper.sol";
import {ERC20ToERC7984WrapperAdvanced} from "../../token/extensions/ERC20ToERC7984WrapperAdvanced.sol";

/// @dev Minimal ERC-20 with a public mint function, used for testing.
contract ERC20Mock is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals_) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @dev Common interface for all {ERC20ToERC7984Wrapper} test implementations (basic, advanced).
 */
interface IERC20ToERC7984WrapperTestableMock is IERC20ToERC7984Wrapper, IERC1363Receiver {}

/// @dev Implementation of {ERC20ToERC7984Wrapper} for testing.
contract ERC20ToERC7984WrapperMock is IERC20ToERC7984WrapperTestableMock, ERC20ToERC7984Wrapper {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC7984(name, symbol, contractURI) ERC20ToERC7984Wrapper(underlying) {}
}

/// @dev Implementation of {ERC20ToERC7984WrapperAdvanced} for testing.
contract ERC20ToERC7984WrapperAdvancedMock is
    IERC20ToERC7984WrapperTestableMock,
    ERC20ToERC7984WrapperAdvanced
{
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI,
        IERC20 underlying
    ) ERC7984Advanced(name, symbol, contractURI) ERC20ToERC7984WrapperAdvanced(underlying) {}
}
