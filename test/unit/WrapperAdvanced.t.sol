// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ERC20ToERC7984WrapperAdvancedMock,
    WrapperMock
} from "../../contracts/mocks/token/WrapperMock.sol";
import {WrapperCommonTest} from "./WrapperCommon.sol";

contract ERC20ToERC7984WrapperAdvancedTest is WrapperCommonTest {
    function _getTokenInstance() internal override returns (WrapperMock) {
        return new ERC20ToERC7984WrapperAdvancedMock(NAME, SYMBOL, URI, underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984WrapperAdvanced";
    }
}
