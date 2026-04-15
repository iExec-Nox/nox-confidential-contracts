// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984Mock, IERC7984TestableMock} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984CommonTest} from "./ERC7984Common.sol";

contract ERC7984Test is ERC7984CommonTest {
    function _getTokenInstance() internal override returns (IERC7984TestableMock) {
        return new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984Mock";
    }

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
