// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC7984} from "../../contracts/token/ERC7984NonUpgradeable.sol";

contract ERC7984Mock is ERC7984 {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) ERC7984(name, symbol, contractURI) {}
}

contract ERC7984Test is Test {
    string constant NAME = "Test Non-Upgradeable Token";
    string constant SYMBOL = "TNT";
    string constant CONTRACT_URI = "https://example.com/";

    ERC7984Mock token = new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI);

    function test_init() public view {
        // Check that the constructor calls `__ERC7984Base`.
        assertEq(token.name(), NAME);
        assertEq(token.symbol(), SYMBOL);
        assertEq(token.contractURI(), CONTRACT_URI);
    }
}
