// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
// TODO: Once IACL and INoxCompute are merged into a single interface in the npm package,
// remove the IACL import and update all ACL mock calls to use INoxCompute directly.
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {IACL} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/IACL.sol";
import {euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMock is Test {
    // TODO: Replace hardcoded addresses with Nox._compute()/_acl() when exposed publicly.
    // NoxCompute address on local dev chain (chainid 31337) - from Nox._compute() in beta.4.
    address internal constant NOX_COMPUTE = 0x463Bdd46031353138713a47D7056F7c85024a4A6;
    // ACL address on local dev chain (chainid 31337) - from Nox._acl() in beta.4.
    address internal constant NOX_ACL = 0x3219A802B61028Fc29848863268FE17d750E5701;

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
        vm.mockCall(NOX_ACL, abi.encodeWithSelector(IACL.isAllowed.selector), abi.encode(true));
        vm.mockCall(NOX_ACL, abi.encodeWithSelector(IACL.allow.selector), "");
        vm.mockCall(NOX_ACL, abi.encodeWithSelector(IACL.allowTransient.selector), "");
    }

    /// @dev Mocks a specific `isAllowed` call for the given encrypted amount handle and user.
    function _mockIsAllowedCall(euint256 amount, address user, bool allowed) internal {
        vm.mockCall(
            NOX_ACL,
            abi.encodeWithSelector(IACL.isAllowed.selector, euint256.unwrap(amount), user),
            abi.encode(allowed)
        );
    }
}
