// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984CommonTest} from "../../utils/ERC7984Common.sol";
import {TokenMock} from "../../../contracts/mocks/token/TokenMock.sol";
import {ERC7984RawMock} from "../../../contracts/mocks/token/TokenMock.sol";

contract ERC7984RawTest is ERC7984CommonTest {
    function _getTestedContractInstance() internal override returns (TokenMock) {
        return new ERC7984RawMock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984RawMock";
    }

    // ============ primitives assertions ============

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
