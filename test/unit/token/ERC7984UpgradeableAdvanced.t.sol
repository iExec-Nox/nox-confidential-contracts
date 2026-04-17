// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984CommonTest} from "../../utils/ERC7984Common.sol";
import {
    TokenMock,
    ERC7984UpgradeableAdvancedMock
} from "../../../contracts/mocks/token/TokenMock.sol";

contract ERC7984UpgradeableAdvancedTest is ERC7984CommonTest {
    function _getTestedContractInstance() internal override returns (TokenMock) {
        ERC7984UpgradeableAdvancedMock impl = new ERC7984UpgradeableAdvancedMock();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(ERC7984UpgradeableAdvancedMock.initialize, (NAME, SYMBOL, CONTRACT_URI))
        );
        return TokenMock(address(proxy));
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984UpgradeableAdvanced";
    }

    // ============ initialize ============

    function test_CannotInitializeTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        ERC7984UpgradeableAdvancedMock(address(token)).initialize(NAME, SYMBOL, CONTRACT_URI);
    }

    // ============ primitives ============

    function _assertUsedPrimitivesForMint() internal override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.mint.selector));
    }

    function _assertUsedPrimitivesForBurn() internal override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.burn.selector));
    }

    function _assertUsedPrimitivesForTransfer() internal override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.transfer.selector));
    }
}
