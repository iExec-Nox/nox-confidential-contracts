// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {Nox, euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMock is Test {
    address internal noxCompute = address(Nox.noxComputeContract());

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    /// @dev Mocks all Nox TEE primitive calls needed for tests that exercise
    /// the real _update path or any function relying on TEE arithmetic.
    function _mockNoxPrimitives() internal {
        address compute = Nox.noxComputeContract();
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.plaintextToEncrypted.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.select.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.safeSub.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.sub.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.add.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.isAllowed.selector),
            abi.encode(true)
        );
        vm.mockCall(noxCompute, abi.encodeWithSelector(INoxCompute.allow.selector), "");
        vm.mockCall(noxCompute, abi.encodeWithSelector(INoxCompute.allowTransient.selector), "");
    }

    /// @dev Mocks a specific `isAllowed` call for the given encrypted amount handle and user.
    function _mockIsAllowedCall(euint256 amount, address user, bool allowed) internal {
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.isAllowed.selector, euint256.unwrap(amount), user),
            abi.encode(allowed)
        );
    }
}
