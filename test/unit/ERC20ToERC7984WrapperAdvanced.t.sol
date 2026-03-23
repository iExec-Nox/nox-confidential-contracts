// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ERC20ToERC7984WrapperAdvancedMock,
    IERC20ToERC7984WrapperTestableMock
} from "../../contracts/mocks/token/ERC20ToERC7984WrapperMock.sol";
import {ERC20ToERC7984WrapperTest} from "./ERC20ToERC7984Wrapper.t.sol";

contract ERC20ToERC7984WrapperAdvancedTest is ERC20ToERC7984WrapperTest {
    function _getTokenInstance() internal override returns (IERC20ToERC7984WrapperTestableMock) {
        return new ERC20ToERC7984WrapperAdvancedMock(NAME, SYMBOL, URI, underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984WrapperAdvanced";
    }
}
