// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IIdentityRegistry} from "../../interfaces/IIdentityRegistry.sol";

/**
 * @dev Simple implementation of {IIdentityRegistry} for testing purposes.
 *
 * Stores a `verified` flag per account. The `setVerified` convenience
 * function allows tests to control verification status without deploying
 * claim issuers.
 */
contract IdentityRegistryMock is IIdentityRegistry {
    mapping(address account => bool) private _verified;

    /**
     * @dev Sets the verified status for `account`. Convenience function for tests.
     */
    function setVerified(address account, bool verified) external {
        _verified[account] = verified;
    }

    /// @inheritdoc IIdentityRegistry
    function isVerified(address account) external view returns (bool) {
        return _verified[account];
    }
}
