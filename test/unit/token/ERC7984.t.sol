// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {ERC7984CommonTest} from "../../utils/ERC7984Common.sol";
import {TokenMock} from "../../../contracts/mocks/token/TokenMock.sol";
import {ERC7984Mock} from "../../../contracts/mocks/token/TokenMock.sol";

contract ERC7984Test is ERC7984CommonTest {
    function _getTestedContractInstance() internal override returns (TokenMock) {
        return new ERC7984Mock(NAME, SYMBOL, CONTRACT_URI);
    }

    function _getTestedContractName() internal pure override returns (string memory) {
        return "ERC7984";
    }

    // ============ primitives assertions ============

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
