// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {
    ERC20Mock,
    ERC20ToERC7984WrapperMock,
    WrapperTestMock
} from "../../../../contracts/mocks/token/WrapperTestMock.sol";
import {WrapperCommonTest} from "../../../utils/WrapperCommon.sol";

contract ERC20ToERC7984WrapperTest is WrapperCommonTest {
    function _getTestedContractInstance() internal override returns (WrapperTestMock) {
        return _newWrapperInstance(NAME, SYMBOL, URI, underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984Wrapper";
    }

    function _newWrapperInstance(
        string memory name,
        string memory symbol,
        string memory uri,
        ERC20Mock underlying_
    ) internal override returns (WrapperTestMock) {
        return new ERC20ToERC7984WrapperMock(name, symbol, uri, underlying_);
    }
}
