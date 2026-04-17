// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984CommonTest} from "../../utils/ERC7984Common.sol";
import {TokenMock, ERC7984RawUpgradeableMock} from "../../../contracts/mocks/token/TokenMock.sol";

contract ERC7984RawUpgradeableTest is ERC7984CommonTest {
    function _getTestedContractInstance() internal override returns (TokenMock) {
        ERC7984RawUpgradeableMock impl = new ERC7984RawUpgradeableMock();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(ERC7984RawUpgradeableMock.initialize, (NAME, SYMBOL, CONTRACT_URI))
        );
        return TokenMock(address(proxy));
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984RawUpgradeable";
    }

    // ============ initialize ============

    function test_CannotInitializeTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        ERC7984RawUpgradeableMock(address(token)).initialize(NAME, SYMBOL, CONTRACT_URI);
    }

    // ============ primitives ============

    function _assertUsedPrimitivesForMint() internal override {
        _expectSafeAddCall();
        _expectAddCall();
        _expectSelectCall();
    }

    function _assertUsedPrimitivesForBurn() internal override {
        _expectSafeSubCall();
        _expectSubCall();
        _expectSelectCall();
    }

    function _assertUsedPrimitivesForTransfer() internal override {
        _expectSafeSubCall();
        _expectAddCall();
        _expectSelectCall();
    }

    function _expectAddCall() private {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.add.selector));
    }

    function _expectSubCall() private {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.sub.selector));
    }

    function _expectSafeAddCall() private {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.safeAdd.selector));
    }

    function _expectSafeSubCall() private {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.safeSub.selector));
    }

    function _expectSelectCall() private {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.select.selector));
    }
}
