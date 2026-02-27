// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMock is Test {
    // TODO: Replace hardcoded addresses with Nox._acl() / Nox._compute() when exposed publicly.
    // Contract addresses on local dev chain (chainid 31337)
    address internal constant ACL = 0x3219A802B61028Fc29848863268FE17d750E5701;
    address internal constant COMPUTE = 0x463Bdd46031353138713a47D7056F7c85024a4A6;

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    /// @dev Mocks all Nox TEE primitive calls (COMPUTE and ACL) needed for tests that exercise
    /// the real _update path or any function relying on TEE arithmetic.
    function _mockNoxPrimitives() internal {
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSelector(INoxCompute.plaintextToEncrypted.selector),
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
            abi.encodeWithSignature("sub(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            COMPUTE,
            abi.encodeWithSignature("add(bytes32,bytes32)"),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(ACL, abi.encodeWithSignature("isAllowed(bytes32,address)"), abi.encode(true));
        vm.mockCall(ACL, abi.encodeWithSignature("allow(bytes32,address)"), "");
        vm.mockCall(ACL, abi.encodeWithSignature("allowTransient(bytes32,address)"), "");
    }

    /// @dev Mocks a specific `isAllowed` ACL call for the given encrypted amount handle and user.
    function _mockIsAllowedCall(euint256 amount, address user, bool allowed) internal {
        vm.mockCall(
            ACL,
            abi.encodeWithSignature("isAllowed(bytes32,address)", euint256.unwrap(amount), user),
            abi.encode(allowed)
        );
    }
}
