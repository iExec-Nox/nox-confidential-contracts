// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {WrapperCommonTest} from "../../utils/WrapperCommon.sol";
import {
    ERC20Mock,
    WrapperTestMock,
    WrapperUpgradeableMock
} from "../../../contracts/mocks/token/WrapperTestMock.sol";

contract WrapperUpgradeableTest is WrapperCommonTest {
    function _getTestedContractInstance() internal override returns (WrapperTestMock) {
        return _newWrapperInstance(NAME, SYMBOL, URI, underlying6);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC20ToERC7984WrapperUpgradeable";
    }

    function _newWrapperInstance(
        string memory name,
        string memory symbol,
        string memory contractURI,
        ERC20Mock underlying_
    ) internal override returns (WrapperTestMock) {
        WrapperUpgradeableMock impl = new WrapperUpgradeableMock(underlying_);
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(WrapperUpgradeableMock.initialize, (name, symbol, contractURI))
        );
        return WrapperTestMock(address(proxy));
    }

    // ============ initialize ============

    function test_CannotInitializeTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        WrapperUpgradeableMock(address(wrapper)).initialize(NAME, SYMBOL, URI);
    }
}
