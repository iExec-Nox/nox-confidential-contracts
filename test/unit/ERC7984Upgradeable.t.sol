// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC7984Upgradeable} from "../../contracts/token/ERC7984Upgradeable.sol";

contract ERC7984UpgradeableMock is ERC7984Upgradeable {
    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) public initializer {
        __ERC7984_init(name, symbol, contractURI);
    }
}

contract ERC7984UpgradeableTest is Test {
    string constant NAME = "Test Upgradeable Token";
    string constant SYMBOL = "TUT";
    string constant CONTRACT_URI = "https://example.com/";

    ERC7984UpgradeableMock token = new ERC7984UpgradeableMock();

    function test_init() public {
        token.initialize(NAME, SYMBOL, CONTRACT_URI);
        // Check that the function `__ERC7984_init` calls `__ERC7984Base`.
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.contractURI(), CONTRACT_URI);
    }
}
