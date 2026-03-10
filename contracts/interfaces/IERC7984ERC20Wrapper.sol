// SPDX-License-Identifier: Apache-2.0
// Inspired by OpenZeppelin Confidential Contracts (token/ERC7984/extensions/ERC7984ERC20Wrapper.sol)
pragma solidity ^0.8.28;

import {euint256, externalEuint256} from "@iexec-nox/nox-protocol-contracts/contracts/sdk/Nox.sol";
import {IERC7984} from "./IERC7984.sol";

/// @dev Interface for ERC7984ERC20Wrapper contract.
interface IERC7984ERC20Wrapper is IERC7984 {
    /**
     * @dev Wraps `amount` of the underlying ERC-20 token into a confidential token and sends it to `to`.
     * Tokens are exchanged 1:1. Returns the encrypted amount of wrapped tokens.
     */
    function wrap(address to, uint256 amount) external returns (euint256);

    /**
     * @dev Unwraps confidential tokens from `from` and sends underlying ERC-20 tokens to `to`.
     * The caller must be `from` or an approved operator for `from`.
     * The caller *must* already be allowed by ACL for the given `amount`.
     *
     * NOTE: The unwrap request created by this function must be finalized by calling {finalizeUnwrap}.
     */
    function unwrap(address from, address to, euint256 amount) external returns (euint256);

    /**
     * @dev Same as {unwrap}, but accepts an external encrypted amount with an input proof
     * instead of requiring prior ACL access.
     */
    function unwrap(
        address from,
        address to,
        externalEuint256 encryptedAmount,
        bytes calldata inputProof
    ) external returns (euint256);

    /// @dev Returns the address of the underlying ERC-20 token being wrapped.
    function underlying() external view returns (address);
}
