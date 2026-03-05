// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMock is Test {
    // NoxCompute address on local dev chain (chainid 31337) - merged ACL+Compute contract.
    // Source: Nox.noxComputeContract() in the current nox-protocol-contracts package.
    address internal constant NOX_COMPUTE = 0x188D560Fd7F60f50e4c32a4484B1D0DC486714b3;

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    /// @dev Mocks all Nox TEE primitive calls needed for tests that exercise
    /// the real _update path or any function relying on TEE arithmetic.
    function _mockNoxPrimitives() internal {
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.plaintextToEncrypted.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.select.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.safeSub.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE)
        );
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.sub.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.add.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.isAllowed.selector),
            abi.encode(true)
        );
        vm.mockCall(NOX_COMPUTE, abi.encodeWithSelector(INoxCompute.allow.selector), "");
        vm.mockCall(NOX_COMPUTE, abi.encodeWithSelector(INoxCompute.allowTransient.selector), "");
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.allowPublicDecryption.selector),
            ""
        );
    }

    /// @dev Mocks a specific `isAllowed` call for the given encrypted amount handle and user.
    function _mockIsAllowedCall(euint256 amount, address user, bool allowed) internal {
        vm.mockCall(
            NOX_COMPUTE,
            abi.encodeWithSelector(INoxCompute.isAllowed.selector, euint256.unwrap(amount), user),
            abi.encode(allowed)
        );
    }
}
