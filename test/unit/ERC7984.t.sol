// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC7984Mock, IERC7984TestableMock} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984ReceiverMock} from "../../contracts/mocks/token/ERC7984ReceiverMock.sol";
import {ERC7984CommonTest} from "./ERC7984Common.sol";

contract ERC7984Test is ERC7984CommonTest {
    function _getTokenInstance() internal override returns (IERC7984TestableMock) {
        return new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984Mock";
    }

    // function test_ShouldUseAdvancedPrimitives() public {

    //     assertEq(token.getPrimitiveType(), 2);
    // }
}
