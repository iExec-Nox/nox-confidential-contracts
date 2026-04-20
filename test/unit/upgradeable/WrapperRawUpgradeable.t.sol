// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {WrapperCommonTest} from "../../utils/WrapperCommon.sol";
import {
    ERC20Mock,
    WrapperTestMock,
    WrapperRawUpgradeableMock
} from "../../../contracts/mocks/token/WrapperTestMock.sol";

contract WrapperRawUpgradeableTest is WrapperCommonTest {
    function _getTestedContractInstance() internal override returns (WrapperTestMock) {
        return _newWrapperInstance(NAME, SYMBOL, URI, underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984WrapperRawUpgradeable";
    }

    function _newWrapperInstance(
        string memory name,
        string memory symbol,
        string memory contractURI,
        ERC20Mock underlying_
    ) internal override returns (WrapperTestMock) {
        WrapperRawUpgradeableMock impl = new WrapperRawUpgradeableMock(underlying_);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(WrapperRawUpgradeableMock.initialize, (name, symbol, contractURI))
        );
        return WrapperTestMock(address(proxy));
    }

    // ============ initialize ============

    function test_CannotInitializeTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        WrapperRawUpgradeableMock(address(wrapper)).initialize(NAME, SYMBOL, URI);
    }
}
