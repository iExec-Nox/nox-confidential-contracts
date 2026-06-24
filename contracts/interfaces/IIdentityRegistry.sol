// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @dev Identity registry interface for ERC-3643 confidential tokens.
 *
 * Links wallet addresses to on-chain identity contracts and verifies
 * investor eligibility based on claims fetched from trusted issuers
 * and claim topics registries.
 */
interface IIdentityRegistry {
    /**
     * @dev Checks whether an identity contract corresponding to the provided user address
     * has the required claims or not based on the data fetched from trusted issuers registry
     * and from the claim topics registry.
     * @param userAddress the address of the user to be verified.
     * @return `true` if the address is verified, `false` if not.
     */
    function isVerified(address userAddress) external view returns (bool);
}
