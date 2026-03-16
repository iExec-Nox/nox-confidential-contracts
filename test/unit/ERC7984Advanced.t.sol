// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {
    ERC7984AdvancedMock,
    IERC7984TestableMock
} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984Test} from "./ERC7984.t.sol";

contract ERC7984AdvancedTest is ERC7984Test {
    function _getTokenInstance() internal override returns (IERC7984TestableMock) {
        return new ERC7984AdvancedMock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984Advanced";
    }
}
