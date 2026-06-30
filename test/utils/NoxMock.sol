// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {INoxCompute} from "@iexec-nox/nox-protocol-contracts/contracts/interfaces/INoxCompute.sol";
import {Nox, euint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {HandleUtils} from "@iexec-nox/nox-protocol-contracts/contracts/utils/HandleUtils.sol";
import {TEEType} from "@iexec-nox/nox-protocol-contracts/contracts/utils/TypeUtils.sol";

/**
 * @dev Test utility library providing mock helpers for Nox TEE primitives.
 */
abstract contract NoxMock is Test {
    address internal noxCompute = address(Nox.noxComputeContract());

    // Fake handle returned by mocked compute operations.
    bytes32 internal constant MOCK_HANDLE = bytes32(uint256(999));

    bytes32 internal constant MOCK_TOTAL_SUPPLY_HANDLE = bytes32(
        (uint256(1) << 200) | uint256(888)
    );

    /// @dev Mocks all Nox TEE primitive calls needed for tests that exercise
    /// the real _update path or any function relying on TEE arithmetic.
    function _mockNoxPrimitives() internal {
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.wrapAsPublicHandle.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.select.selector),
            abi.encode(MOCK_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.safeAdd.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE)
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
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.mint.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE, MOCK_TOTAL_SUPPLY_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.burn.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE, MOCK_TOTAL_SUPPLY_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.transfer.selector),
            abi.encode(MOCK_HANDLE, MOCK_HANDLE, MOCK_HANDLE)
        );
    }

    /// @dev Asserts that `Nox.allowThis(handle)` is invoked, i.e. that
    /// `INoxCompute.allow(handle, account)` is called for the given handle and account.
    /// Must be called before the action expected to trigger the ACL grant. Only meaningful
    /// for non-public handles (allowThis is skipped for public handles), see MOCK_TOTAL_SUPPLY_HANDLE.
    function _expectAllowThisCall(bytes32 handle, address account) internal {
        vm.expectCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.allow.selector, handle, account)
        );
    }

    function _expectRawAllowThisOnNewTotalSupply(address account) internal {
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(
                INoxCompute.select.selector,
                MOCK_HANDLE,
                MOCK_HANDLE,
                HandleUtils.zeroHandle(TEEType.Uint256)
            ),
            abi.encode(MOCK_TOTAL_SUPPLY_HANDLE)
        );
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.sub.selector),
            abi.encode(MOCK_TOTAL_SUPPLY_HANDLE)
        );
        _expectAllowThisCall(MOCK_TOTAL_SUPPLY_HANDLE, account);
    }

    /// @dev Overrides the mocked `transfer` primitive to return specific handles. Useful to
    /// distinguish the new sender balance from the new recipient balance, e.g. to assert that a
    /// self-transfer does not inflate the balance by writing the recipient balance over the sender's.
    function _mockTransferReturning(
        bytes32 success,
        bytes32 newFromBalance,
        bytes32 newToBalance
    ) internal {
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.transfer.selector),
            abi.encode(success, newFromBalance, newToBalance)
        );
    }

    /// @dev Mocks a specific `isAllowed` call for the given encrypted amount handle and user.
    function _mockIsAllowedCall(euint256 amount, address user, bool allowed) internal {
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.isAllowed.selector, euint256.unwrap(amount), user),
            abi.encode(allowed)
        );
    }

    /// @dev Mocks `publicDecrypt` call and returns the given plaintext amount.
    function _mockPublicDecryptCall(uint256 returnValue) internal {
        bytes memory returnValueAsBytes = abi.encode(returnValue);
        vm.mockCall(
            noxCompute,
            abi.encodeWithSelector(INoxCompute.validateDecryptionProof.selector),
            abi.encode(returnValueAsBytes)
        );
    }
}
