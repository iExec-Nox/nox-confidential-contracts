// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMocks is Test {
    // NoxCompute address on local dev chain (chainid 31337).
    // ACL is merged into NoxCompute (no separate ACL contract).
    address internal constant COMPUTE = 0xE9Cba9b8F4D540C2eE6f27033cb864952521Fc57;

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    /// @dev Mocks all Nox TEE primitive calls needed for tests that exercise
    /// the real _update path or any function relying on TEE arithmetic.
    function _mockNoxPrimitives() internal {
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("plaintextToEncrypted(bytes32,uint8)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("select(bytes32,bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("safeSub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("safeAdd(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("sub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("add(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("isAllowed(bytes32,address)"),
            abi.encode(true)
        );
        vm.mockCall(COMPUTE, abi.encodeWithSignature("allow(bytes32,address)"), "");
        vm.mockCall(COMPUTE, abi.encodeWithSignature("allowTransient(bytes32,address)"), "");
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("validateProof(bytes32,address,bytes,uint8)"),
            ""
        );
    }
}
