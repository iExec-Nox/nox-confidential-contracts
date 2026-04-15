// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {
    ERC7984AdvancedMock,
    IERC7984TestableMock
} from "../../contracts/mocks/token/ERC7984Mock.sol";
import {ERC7984ReceiverMock} from "../../contracts/mocks/token/ERC7984ReceiverMock.sol";
import {ERC7984CommonTest} from "./ERC7984Common.sol";

contract ERC7984AdvancedTest is ERC7984CommonTest {
    function _getTokenInstance() internal override returns (IERC7984TestableMock) {
        return new ERC7984AdvancedMock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984Advanced";
    }

    function _assertUsedPrimitivesForMint() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.mint.selector));
    }

    function _assertUsedPrimitivesForBurn() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.burn.selector));
    }

    function _assertUsedPrimitivesForTransfer() internal virtual override {
        vm.expectCall(noxCompute, abi.encodeWithSelector(INoxCompute.transfer.selector));
    }
}
