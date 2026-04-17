// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ERC20Mock,
    ERC20ToERC7984WrapperAdvancedMock,
    WrapperMock
} from "../../contracts/mocks/token/WrapperMock.sol";
import {WrapperCommonTest} from "../utils/WrapperCommon.sol";

contract ERC20ToERC7984WrapperAdvancedTest is WrapperCommonTest {
    function _getTestedContractInstance() internal override returns (WrapperMock) {
        return _newWrapperFor(underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984WrapperAdvanced";
    }

    function _newWrapperFor(ERC20Mock underlying_) internal override returns (WrapperMock) {
        return new ERC20ToERC7984WrapperAdvancedMock(NAME, SYMBOL, URI, underlying_);
    }
}
